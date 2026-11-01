<?php
/**
 * REST API: Update Pothole Status / Assign Repair Crew
 * Updates both Local SQLite Authority Database and Supabase Cloud Backend
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    $report_id = trim($_POST['report_id'] ?? '');
    $status = trim($_POST['status'] ?? '');
    $assigned_crew = trim($_POST['assigned_crew'] ?? '');
    $assigned_crew_id = trim($_POST['assigned_crew_id'] ?? '');
    $scheduled_date = !empty($_POST['scheduled_repair_date']) ? $_POST['scheduled_repair_date'] : null;
    $notes = trim($_POST['repair_notes'] ?? '');

    if (empty($report_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Report ID is required']);
        exit;
    }

    // Check existing in SQLite
    $chk = $db->prepare("SELECT * FROM pothole_reports WHERE id = :id");
    $chk->execute([':id' => $report_id]);
    $existing = $chk->fetch();

    if (!$existing) {
        http_response_code(404);
        echo json_encode(['success' => false, 'error' => "Report {$report_id} not found."]);
        exit;
    }

    require_once __DIR__ . '/../includes/auth.php';

    // Permission Enforcement:
    // Road Authority can change any defect status and assign any crew.
    // Construction Crew can ONLY change defects assigned to their own ID or Name!
    $authUser = Auth::user();
    if ($authUser && $authUser['role'] === 'crew') {
        $existingCrewId = $existing['assigned_crew_id'] ?? '';
        $existingCrewName = strtolower($existing['assigned_crew'] ?? '');
        $currentUserId = $authUser['id'] ?? '';
        $currentUserName = strtolower($authUser['name'] ?? '');

        $isAssignedToCurrentCrew = ($existingCrewId && $existingCrewId === $currentUserId) ||
                                   ($currentUserName && strpos($existingCrewName, $currentUserName) !== false);

        if (!$isAssignedToCurrentCrew) {
            http_response_code(403);
            echo json_encode([
                'success' => false,
                'error' => "Permission Denied: Without authority permission, a crew member can only view other crews' road defects and cannot modify their status."
            ]);
            exit;
        }
    }

    $new_status = !empty($status) ? $status : ($existing['status'] ?? 'detected');
    $new_crew = !empty($assigned_crew) ? $assigned_crew : ($existing['assigned_crew'] ?? null);
    $new_crew_id = !empty($assigned_crew_id) ? $assigned_crew_id : ($existing['assigned_crew_id'] ?? null);
    $new_notes = !empty($notes) ? $notes : ($existing['repair_notes'] ?? null);
    $new_sched = !empty($scheduled_date) ? $scheduled_date : ($existing['scheduled_repair_date'] ?? null);

    // Handle timestamps
    $assigned_at = $existing['assigned_at'] ?? null;
    if ($new_status === 'assigned' || !empty($new_crew)) {
        if (empty($assigned_at)) {
            $assigned_at = date('Y-m-d H:i:s');
        }
    }

    $repair_completed_at = $existing['repair_completed_at'] ?? null;
    if ($new_status === 'resolved' && empty($repair_completed_at)) {
        $repair_completed_at = date('Y-m-d H:i:s');
    }

    // Handle verification metadata for Authority sign-off
    $verified_by_id = $existing['verified_by_id'] ?? null;
    $verified_by_name = $existing['verified_by_name'] ?? null;
    $verified_at = $existing['verified_at'] ?? null;
    $verified_notes = !empty($_POST['verified_notes']) ? trim($_POST['verified_notes']) : ($existing['verified_notes'] ?? null);

    if ($new_status === 'verified') {
        if ($authUser) {
            $verified_by_id = $authUser['id'] ?? 'auth_admin';
            $verified_by_name = $authUser['name'] ?? 'Road Authority Engineer';
        } else {
            $verified_by_id = !empty($_POST['verified_by_id']) ? trim($_POST['verified_by_id']) : ($existing['verified_by_id'] ?? 'auth_admin');
            $verified_by_name = !empty($_POST['verified_by_name']) ? trim($_POST['verified_by_name']) : ($existing['verified_by_name'] ?? 'Road Authority Engineer');
        }
        $verified_at = date('Y-m-d H:i:s');
    }

    // Handle repair proof image upload if provided
    $repair_image_url = $existing['repair_image_url'] ?? null;
    if (!empty($_FILES['repair_image']) && $_FILES['repair_image']['error'] === UPLOAD_ERR_OK) {
        $ext = strtolower(pathinfo($_FILES['repair_image']['name'], PATHINFO_EXTENSION));
        $filename = 'repair_' . strtolower($report_id) . '_' . time() . '.' . $ext;
        if (move_uploaded_file($_FILES['repair_image']['tmp_name'], UPLOAD_DIR . $filename)) {
            $repair_image_url = UPLOAD_URL . $filename;
        }
    }

    // MANDATORY REPAIR PHOTO ENFORCEMENT:
    // Without uploading repair photo, status CANNOT be changed to 'resolved' (Repaired)
    if ($new_status === 'resolved' && empty($repair_image_url)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => "Cannot mark as Repaired: Please upload a Repair Proof Photo first before marking status as Repaired / Resolved."
        ]);
        exit;
    }

    // 1. Update SQLite Local Record
    $stmt = $db->prepare("
        UPDATE pothole_reports 
        SET status = :status,
            assigned_crew = :assigned_crew,
            assigned_crew_id = :assigned_crew_id,
            assigned_at = :assigned_at,
            scheduled_repair_date = :scheduled_date,
            repair_notes = :notes,
            repair_image_url = :repair_image_url,
            repair_completed_at = :repair_completed_at,
            verified_by_id = :verified_by_id,
            verified_by_name = :verified_by_name,
            verified_at = :verified_at,
            verified_notes = :verified_notes,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = :id
    ");
    $stmt->execute([
        ':status' => $new_status,
        ':assigned_crew' => $new_crew,
        ':assigned_crew_id' => $new_crew_id,
        ':assigned_at' => $assigned_at,
        ':scheduled_date' => $new_sched,
        ':notes' => $new_notes,
        ':repair_image_url' => $repair_image_url,
        ':repair_completed_at' => $repair_completed_at,
        ':verified_by_id' => $verified_by_id,
        ':verified_by_name' => $verified_by_name,
        ':verified_at' => $verified_at,
        ':verified_notes' => $verified_notes,
        ':id' => $report_id
    ]);

    // 2. Sync Status Update to Supabase Cloud Database
    $supabase_sync_success = false;
    $supabase_url = SUPABASE_URL . '/rest/v1/damage_reports?id=eq.' . urlencode($report_id);
    
    // Map status if needed (prompt.md statuses: 'detected', 'investigating', 'in_progress', 'resolved', 'verified')
    $supabase_status = $new_status;
    if ($new_status === 'reported') $supabase_status = 'detected';
    if ($new_status === 'assigned') $supabase_status = 'in_progress';
    if ($new_status === 'under_repair') $supabase_status = 'in_progress';

    $payload = json_encode(['status' => $supabase_status]);

    $ch = curl_init($supabase_url);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PATCH');
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 5);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'apikey: ' . SUPABASE_ANON_KEY,
        'Authorization: Bearer ' . SUPABASE_ANON_KEY,
        'Content-Type: application/json',
        'Prefer: return=minimal'
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    $res = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($http_code >= 200 && $http_code < 300) {
        $supabase_sync_success = true;
    }

    echo json_encode([
        'success' => true,
        'report_id' => $report_id,
        'status' => $new_status,
        'assigned_crew' => $new_crew,
        'assigned_crew_id' => $new_crew_id,
        'scheduled_repair_date' => $new_sched,
        'repair_notes' => $new_notes,
        'repair_image_url' => $repair_image_url,
        'supabase_synced' => $supabase_sync_success
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
