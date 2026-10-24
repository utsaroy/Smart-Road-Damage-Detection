<?php
/**
 * REST API: Update Pothole Status / Assign Repair Crew
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
    $scheduled_date = !empty($_POST['scheduled_repair_date']) ? $_POST['scheduled_repair_date'] : null;
    $notes = trim($_POST['repair_notes'] ?? '');

    if (empty($report_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Report ID is required']);
        exit;
    }

    $chk = $db->prepare("SELECT * FROM pothole_reports WHERE id = :id");
    $chk->execute([':id' => $report_id]);
    $existing = $chk->fetch();

    $new_status = !empty($status) ? $status : ($existing['status'] ?? 'detected');
    $new_crew = !empty($assigned_crew) ? $assigned_crew : ($existing['assigned_crew'] ?? null);
    $new_notes = !empty($notes) ? $notes : ($existing['repair_notes'] ?? null);

    $repair_image_url = $existing['repair_image_url'] ?? null;
    if (!empty($_FILES['repair_image']) && $_FILES['repair_image']['error'] === UPLOAD_ERR_OK) {
        $ext = strtolower(pathinfo($_FILES['repair_image']['name'], PATHINFO_EXTENSION));
        $filename = 'repair_' . strtolower($report_id) . '_' . time() . '.' . $ext;
        if (move_uploaded_file($_FILES['repair_image']['tmp_name'], UPLOAD_DIR . $filename)) {
            $repair_image_url = UPLOAD_URL . $filename;
        }
    }

    $stmt = $db->prepare("
        UPDATE pothole_reports 
        SET status = :status,
            assigned_crew = :assigned_crew,
            scheduled_repair_date = :scheduled_date,
            repair_notes = :notes,
            repair_image_url = :repair_image_url,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = :id
    ");
    $stmt->execute([
        ':status' => $new_status,
        ':assigned_crew' => $new_crew,
        ':scheduled_date' => $scheduled_date,
        ':notes' => $new_notes,
        ':repair_image_url' => $repair_image_url,
        ':id' => $report_id
    ]);

    echo json_encode([
        'success' => true,
        'report_id' => $report_id,
        'status' => $new_status,
        'assigned_crew' => $new_crew,
        'scheduled_repair_date' => $scheduled_date,
        'repair_notes' => $new_notes,
        'repair_image_url' => $repair_image_url
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
