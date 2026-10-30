<?php
/**
 * REST API: Report Pothole / Road Hazard
 * Used by Android App (sorok_surokkha YOLOv8 Detection Engine) to automatically store live detection data.
 * Supports:
 * - Single DamageReport (JSON or multipart/form-data)
 * - Batch array of DamageReports (e.g. offline queue sync)
 * - Automatic schema mapping for Flutter DamageReport model (camelCase & snake_case)
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Only POST method is allowed']);
    exit;
}

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/geo_helper.php';

try {
    $db = Database::getConnection();

    // Check if raw JSON body
    $raw_input = file_get_contents('php://input');
    $json_data = json_decode($raw_input, true);

    $items_to_process = [];

    if (!empty($json_data)) {
        if (isset($json_data['reports']) && is_array($json_data['reports'])) {
            $items_to_process = $json_data['reports'];
        } elseif (array_is_list($json_data) && !empty($json_data) && is_array($json_data[0])) {
            $items_to_process = $json_data;
        } else {
            $items_to_process = [$json_data];
        }
    } else {
        $items_to_process = [$_POST];
    }

    $inserted_reports = [];

    $stmt = $db->prepare("
        INSERT INTO pothole_reports (
            id, title, severity, status, latitude, longitude,
            road_name, division, district, upazilla, landmark, confidence, defects_count,
            hazards_breakdown, image_url, model_name, inference_time_ms,
            detection_source, user_id, user_name, device_model, user_phone,
            repair_notes, damage_type, address, damage_area_sqm,
            crack_width_mm, estimated_depth_cm, bbox_left, bbox_top,
            bbox_right, bbox_bottom, image_width, image_height,
            detections_json, reported_at, updated_at
        ) VALUES (
            :id, :title, :severity, :status, :latitude, :longitude,
            :road_name, :division, :district, :upazilla, :landmark, :confidence, :defects_count,
            :hazards_breakdown, :image_url, :model_name, :inference_time_ms,
            'android_ai_scanner', :user_id, :user_name, :device_model, :user_phone,
            :notes, :damage_type, :address, :damage_area_sqm,
            :crack_width_mm, :estimated_depth_cm, :bbox_left, :bbox_top,
            :bbox_right, :bbox_bottom, :image_width, :image_height,
            :detections_json, :reported_at, CURRENT_TIMESTAMP
        )
        ON CONFLICT (id) DO UPDATE SET
            title = EXCLUDED.title,
            severity = EXCLUDED.severity,
            latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            division = EXCLUDED.division,
            district = EXCLUDED.district,
            upazilla = EXCLUDED.upazilla,
            confidence = EXCLUDED.confidence,
            defects_count = EXCLUDED.defects_count,
            hazards_breakdown = EXCLUDED.hazards_breakdown,
            image_url = CASE WHEN EXCLUDED.image_url != 'assets/img/default_pothole.jpg' THEN EXCLUDED.image_url ELSE pothole_reports.image_url END,
            user_id = EXCLUDED.user_id,
            user_name = EXCLUDED.user_name,
            device_model = EXCLUDED.device_model,
            repair_notes = EXCLUDED.repair_notes,
            damage_type = EXCLUDED.damage_type,
            address = EXCLUDED.address,
            damage_area_sqm = EXCLUDED.damage_area_sqm,
            crack_width_mm = EXCLUDED.crack_width_mm,
            estimated_depth_cm = EXCLUDED.estimated_depth_cm,
            bbox_left = EXCLUDED.bbox_left,
            bbox_top = EXCLUDED.bbox_top,
            bbox_right = EXCLUDED.bbox_right,
            bbox_bottom = EXCLUDED.bbox_bottom,
            image_width = EXCLUDED.image_width,
            image_height = EXCLUDED.image_height,
            detections_json = EXCLUDED.detections_json,
            updated_at = CURRENT_TIMESTAMP
    ");

    foreach ($items_to_process as $index => $params) {
        if (!is_array($params)) continue;

        // 1. Report ID
        $report_id = trim($params['id'] ?? $params['report_id'] ?? '');
        if (empty($report_id)) {
            $report_id = 'RPT-' . round(microtime(true) * 1000) . ($index > 0 ? "-{$index}" : "");
        }

        // 2. Coordinates
        $latitude = isset($params['latitude']) ? floatval($params['latitude']) : (isset($params['lat']) ? floatval($params['lat']) : null);
        $longitude = isset($params['longitude']) ? floatval($params['longitude']) : (isset($params['lng']) ? floatval($params['lng']) : null);

        if ($latitude === null || $longitude === null) {
            continue; // Skip items missing GPS coordinates
        }

        // 3. Damage Type & Title
        $damage_type = trim($params['damageType'] ?? $params['damage_type'] ?? 'Pothole');
        $defects_count = intval($params['defects_count'] ?? $params['total_defects'] ?? 1);
        $title = trim($params['title'] ?? ($defects_count > 1 ? "{$damage_type} Cluster ({$defects_count} Defects)" : "{$damage_type} Detected"));

        // 4. Severity
        $severity_raw = strtoupper(trim($params['severity'] ?? 'HIGH'));
        $severity = in_array($severity_raw, ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW']) ? $severity_raw : 'HIGH';

        // 5. Status
        $status = strtolower(trim($params['status'] ?? 'reported'));
        if (!in_array($status, ['reported', 'verified', 'assigned', 'under_repair', 'resolved'])) {
            $status = 'reported';
        }

        // 6. Confidence Score
        $confidence_raw = floatval($params['confidenceScore'] ?? $params['confidence'] ?? 0.85);
        $confidence = $confidence_raw > 1.0 ? ($confidence_raw / 100.0) : $confidence_raw;

        // 7. Identity & Device Info (genuine user info from app)
        $reported_by = trim($params['reportedBy'] ?? $params['user_name'] ?? '');
        $user_id = trim($params['user_id'] ?? '');
        $device_model = trim($params['device_model'] ?? $params['device_info'] ?? '');
        $user_phone = trim($params['user_phone'] ?? $params['phone'] ?? '');

        if (empty($user_id) && !empty($reported_by)) {
            $user_id = 'user_' . substr(md5($reported_by), 0, 8);
        } elseif (empty($user_id)) {
            $user_id = 'app_user_' . substr(md5($_SERVER['REMOTE_ADDR'] ?? microtime()), 0, 6);
        }

        if (empty($reported_by)) {
            $reported_by = 'App User (' . substr($user_id, 0, 8) . ')';
        }

        if (empty($device_model)) {
            $device_model = 'Android Device';
        }

        // 8. Location Details & Upazilla Resolution
        $address = trim($params['address'] ?? $params['road_name'] ?? '');
        $road_name = !empty($address) ? $address : 'Road GPS (' . round($latitude, 5) . ', ' . round($longitude, 5) . ')';
        $landmark = trim($params['landmark'] ?? '');

        // Resolve Division, District, and Upazilla based on coordinates & address
        $rawDistrict = trim($params['district'] ?? '');
        $rawUpazilla = trim($params['upazilla'] ?? '');
        $geoLoc = BangladeshGeo::resolveLocation($latitude, $longitude, $address . ' ' . $road_name, $rawDistrict, $rawUpazilla);
        $division = $geoLoc['division'];
        $district = $geoLoc['district'];
        $upazilla = $geoLoc['upazilla'];

        // 9. Physical Metrics
        $damage_area_sqm = floatval($params['damageAreaSqM'] ?? $params['damage_area_sqm'] ?? 0.0);
        $crack_width_mm = floatval($params['crackWidthMm'] ?? $params['crack_width_mm'] ?? 0.0);
        $estimated_depth_cm = floatval($params['estimatedDepthCm'] ?? $params['estimated_depth_cm'] ?? 0.0);
        $notes = trim($params['notes'] ?? "YOLOv8 detected {$damage_type} (conf: " . round($confidence * 100, 1) . "%).");

        // 10. Bounding Box & Dimensions
        $bbox_left = isset($params['bbox_left']) ? floatval($params['bbox_left']) : null;
        $bbox_top = isset($params['bbox_top']) ? floatval($params['bbox_top']) : null;
        $bbox_right = isset($params['bbox_right']) ? floatval($params['bbox_right']) : null;
        $bbox_bottom = isset($params['bbox_bottom']) ? floatval($params['bbox_bottom']) : null;
        $image_width = isset($params['imageWidth']) ? intval($params['imageWidth']) : (isset($params['image_width']) ? intval($params['image_width']) : null);
        $image_height = isset($params['imageHeight']) ? intval($params['imageHeight']) : (isset($params['image_height']) ? intval($params['image_height']) : null);

        // 11. Detections Breakdown
        $detections = $params['detections'] ?? $params['hazards_breakdown'] ?? null;
        $detections_json = is_array($detections) ? json_encode($detections) : (is_string($detections) ? $detections : null);

        if (empty($detections_json)) {
            $items = [
                [
                    'id' => 1,
                    'type' => $damage_type,
                    'surface_coverage' => max(1.0, round($damage_area_sqm, 2)),
                    'confidence' => round($confidence * 100, 0),
                    'crack_width_mm' => $crack_width_mm,
                    'depth_cm' => $estimated_depth_cm
                ]
            ];
            $detections_json = json_encode($items);
        }

        // 12. Timestamp
        $timestamp = trim($params['timestamp'] ?? $params['reported_at'] ?? '');
        if (!empty($timestamp)) {
            $reported_at = date('Y-m-d H:i:s', strtotime($timestamp));
        } else {
            $reported_at = date('Y-m-d H:i:s');
        }

        // 13. Image Upload (Multipart file, Base64, or existing URL)
        $image_url = 'assets/img/default_pothole.jpg';
        if (!empty($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
            $ext = strtolower(pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION));
            if (!in_array($ext, ['jpg', 'jpeg', 'png', 'webp'])) $ext = 'jpg';
            $saved_name = strtolower($report_id) . '_' . time() . '.' . $ext;
            if (move_uploaded_file($_FILES['image']['tmp_name'], UPLOAD_DIR . $saved_name)) {
                $image_url = UPLOAD_URL . $saved_name;
            }
        } elseif (!empty($params['image_base64'])) {
            $b64 = $params['image_base64'];
            $ext = 'jpg';
            if (preg_match('/^data:image\/(\w+);base64,/', $b64, $m)) {
                $b64 = substr($b64, strpos($b64, ',') + 1);
                $ext = strtolower($m[1]);
            }
            $decoded = base64_decode(str_replace(' ', '+', $b64));
            if ($decoded !== false) {
                $saved_name = strtolower($report_id) . '_' . time() . '.' . $ext;
                file_put_contents(UPLOAD_DIR . $saved_name, $decoded);
                $image_url = UPLOAD_URL . $saved_name;
            }
        } elseif (!empty($params['image_url'])) {
            $image_url = $params['image_url'];
        }

        // 14. Execute DB insertion
        $stmt->execute([
            ':id'                 => $report_id,
            ':title'              => $title,
            ':severity'           => $severity,
            ':status'             => $status,
            ':latitude'           => $latitude,
            ':longitude'          => $longitude,
            ':road_name'          => $road_name,
            ':division'           => $division,
            ':district'           => $district,
            ':upazilla'           => $upazilla,
            ':landmark'           => $landmark,
            ':confidence'         => $confidence,
            ':defects_count'      => $defects_count,
            ':hazards_breakdown'  => $detections_json,
            ':image_url'          => $image_url,
            ':model_name'         => 'best.tflite',
            ':inference_time_ms'  => intval($params['inference_time_ms'] ?? 1450),
            ':user_id'            => $user_id,
            ':user_name'          => $reported_by,
            ':device_model'       => $device_model,
            ':user_phone'         => $user_phone,
            ':notes'              => $notes,
            ':damage_type'        => $damage_type,
            ':address'            => $address,
            ':damage_area_sqm'    => $damage_area_sqm,
            ':crack_width_mm'     => $crack_width_mm,
            ':estimated_depth_cm' => $estimated_depth_cm,
            ':bbox_left'          => $bbox_left,
            ':bbox_top'           => $bbox_top,
            ':bbox_right'         => $bbox_right,
            ':bbox_bottom'        => $bbox_bottom,
            ':image_width'        => $image_width,
            ':image_height'       => $image_height,
            ':detections_json'    => $detections_json,
            ':reported_at'        => $reported_at
        ]);

        $inserted_reports[] = [
            'id' => $report_id,
            'title' => $title,
            'damage_type' => $damage_type,
            'severity' => $severity,
            'latitude' => $latitude,
            'longitude' => $longitude,
            'user_name' => $reported_by,
            'device_model' => $device_model,
            'reported_at' => $reported_at
        ];
    }

    if (empty($inserted_reports)) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'error' => 'No valid reports could be processed. Ensure latitude and longitude are supplied.'
        ]);
        exit;
    }

    http_response_code(201);
    echo json_encode([
        'success' => true,
        'message' => count($inserted_reports) . ' report(s) integrated successfully into website database.',
        'processed_count' => count($inserted_reports),
        'reports' => $inserted_reports
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database ingestion error: ' . $e->getMessage()
    ]);
}
