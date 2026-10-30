<?php
/**
 * REST API: Delete / Archive Pothole Report
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    $report_id = trim($_POST['report_id'] ?? '');
    if (empty($report_id)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Report ID is required']);
        exit;
    }

    $stmt = $db->prepare("DELETE FROM pothole_reports WHERE id = :id");
    $stmt->execute([':id' => $report_id]);

    echo json_encode(['success' => true, 'message' => 'Report deleted successfully']);
} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
