<?php
/**
 * REST API: Get Registered Construction Crews by Upazilla / District
 * Combines Local SQLite Authority Records and Supabase Cloud Profiles
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    $upazilla = trim($_GET['upazilla'] ?? '');
    $district = trim($_GET['district'] ?? '');

    // 1. Fetch from SQLite Users table
    $sql = "
        SELECT 
            u.id, 
            u.name, 
            u.email, 
            u.phone, 
            u.team_name, 
            u.division, 
            u.district, 
            u.upazilla, 
            u.status,
            (SELECT COUNT(*) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status IN ('assigned', 'under_repair')) AS active_tasks_count,
            (SELECT COUNT(*) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status = 'resolved') AS resolved_tasks_count,
            (SELECT GROUP_CONCAT(p.id) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status IN ('assigned', 'under_repair')) AS active_report_ids
        FROM users u
        WHERE u.role = 'crew' AND u.status = 'active'
    ";

    $params = [];

    if (!empty($upazilla)) {
        $sql .= " AND LOWER(u.upazilla) = LOWER(:upazilla)";
        $params[':upazilla'] = $upazilla;
    }

    if (!empty($district)) {
        $sql .= " AND LOWER(u.district) = LOWER(:district)";
        $params[':district'] = $district;
    }

    $sql .= " ORDER BY u.upazilla ASC, u.name ASC";

    $stmt = $db->prepare($sql);
    $stmt->execute($params);
    $crews = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // If specific upazilla has 0 crews, fetch all crews in the district/country as fallback
    if (empty($crews) && !empty($upazilla)) {
        $fallbackStmt = $db->prepare("
            SELECT 
                u.id, u.name, u.email, u.phone, u.team_name, u.division, u.district, u.upazilla, u.status,
                (SELECT COUNT(*) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status IN ('assigned', 'under_repair')) AS active_tasks_count,
                (SELECT COUNT(*) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status = 'resolved') AS resolved_tasks_count,
                (SELECT GROUP_CONCAT(p.id) FROM pothole_reports p WHERE (p.assigned_crew_id = u.id OR p.assigned_crew LIKE '%' || u.name || '%') AND p.status IN ('assigned', 'under_repair')) AS active_report_ids
            FROM users u
            WHERE u.role = 'crew' AND u.status = 'active'
            ORDER BY u.name ASC
        ");
        $fallbackStmt->execute();
        $fallbackCrews = $fallbackStmt->fetchAll(PDO::FETCH_ASSOC);
        if (!empty($fallbackCrews)) {
            $crews = $fallbackCrews;
        }
    }

    // 2. Also attempt to fetch Supabase profiles with role = 'crew'
    try {
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, SUPABASE_URL . '/rest/v1/profiles?role=eq.crew&select=*');
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 3);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'apikey: ' . SUPABASE_ANON_KEY,
            'Authorization: Bearer ' . SUPABASE_ANON_KEY
        ]);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $supaRes = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);

        if ($httpCode >= 200 && $httpCode < 300 && !empty($supaRes)) {
            $supaProfiles = json_decode($supaRes, true) ?: [];
            $existingEmails = array_column($crews, 'email');

            foreach ($supaProfiles as $sp) {
                if (!in_array($sp['email'], $existingEmails)) {
                    $crews[] = [
                        'id' => 'USR-SUPA-' . substr($sp['id'] ?? uniqid(), 0, 8),
                        'name' => $sp['full_name'] ?? 'Field Engineer',
                        'email' => $sp['email'] ?? '',
                        'phone' => '+880 1700-000000',
                        'team_name' => 'Highway Repair Unit',
                        'division' => 'Khulna',
                        'district' => 'Khulna',
                        'upazilla' => $upazilla ?: 'Khan Jahan Ali',
                        'status' => 'active',
                        'active_tasks_count' => 0,
                        'resolved_tasks_count' => 0,
                        'active_report_ids' => null
                    ];
                }
            }
        }
    } catch (Throwable $t) {
        // Fallback gracefully to SQLite records
    }

    echo json_encode([
        'success' => true,
        'count' => count($crews),
        'filter_upazilla' => $upazilla,
        'data' => $crews,
        'crews' => $crews
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage(),
        'data' => [],
        'crews' => []
    ]);
}
