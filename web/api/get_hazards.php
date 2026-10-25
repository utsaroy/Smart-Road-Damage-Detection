<?php
/**
 * REST API: Get Hazard Reports (Powered by Supabase Cloud Database)
 * Retrieves real-time mobile captures uploaded by all users across Bangladesh
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    $status_filter = strtolower(trim($_GET['status'] ?? 'all'));
    $severity_filter = strtoupper(trim($_GET['severity'] ?? 'ALL'));
    $search = trim($_GET['search'] ?? '');

    $supabase_reports = [];
    $fetch_error = null;

    // 1. Fetch from Supabase REST API
    $ch = curl_init();
    $supabase_api_url = SUPABASE_URL . '/rest/v1/damage_reports?select=*&order=created_at.desc';
    
    curl_setopt($ch, CURLOPT_URL, $supabase_api_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 6);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'apikey: ' . SUPABASE_ANON_KEY,
        'Authorization: Bearer ' . SUPABASE_ANON_KEY
    ]);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    $response = curl_exec($ch);
    $curl_err = curl_error($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if (!$curl_err && $http_code >= 200 && $http_code < 300 && !empty($response)) {
        $supabase_reports = json_decode($response, true) ?: [];
    } else {
        $fetch_error = $curl_err ?: ("HTTP " . $http_code);
    }

    // 2. Sync Supabase records into local SQLite database for persistence & authority actions
    if (!empty($supabase_reports) && is_array($supabase_reports)) {
        $upsert_stmt = $db->prepare("
            INSERT INTO pothole_reports (
                id, title, severity, status, latitude, longitude, road_name,
                confidence, defects_count, hazards_breakdown, image_url,
                user_id, user_name, device_model, reported_at
            ) VALUES (
                :id, :title, :severity, :status, :latitude, :longitude, :road_name,
                :confidence, :defects_count, :hazards_breakdown, :image_url,
                :user_id, :user_name, :device_model, :reported_at
            )
            ON CONFLICT(id) DO UPDATE SET
                title = excluded.title,
                severity = excluded.severity,
                latitude = excluded.latitude,
                longitude = excluded.longitude,
                road_name = excluded.road_name,
                confidence = excluded.confidence,
                defects_count = excluded.defects_count,
                hazards_breakdown = excluded.hazards_breakdown,
                image_url = excluded.image_url,
                user_id = excluded.user_id,
                user_name = excluded.user_name,
                reported_at = excluded.reported_at
        ");

        foreach ($supabase_reports as $sr) {
            $rep_id = $sr['id'] ?? ('RPT-' . time());
            $title = $sr['damage_type'] ?? 'Pothole Defect';
            $sev = strtoupper($sr['severity'] ?? 'HIGH');
            $st = strtolower($sr['status'] ?? 'detected');
            $lat = floatval($sr['latitude'] ?? 22.8985);
            $lng = floatval($sr['longitude'] ?? 89.5003);
            $road = !empty($sr['address']) ? $sr['address'] : 'OpenStreetMap Survey Route';
            $conf = floatval($sr['confidence_score'] ?? 0.65);
            
            $dets = $sr['detections'] ?? [];
            if (is_string($dets)) {
                $dets = json_decode($dets, true) ?: [];
            }
            $def_count = !empty($dets) ? count($dets) : 1;
            
            // Format breakdown
            $breakdown = [];
            foreach ($dets as $idx => $d) {
                $lbl = $d['label'] ?? 'Pothole';
                $box = $d['box'] ?? null;
                if (!$box && isset($d['top'], $d['left'], $d['width'], $d['height'])) {
                    $box = [$d['top'], $d['left'], $d['top'] + $d['height'], $d['left'] + $d['width']];
                }
                $coverage = isset($d['width'], $d['height']) ? round($d['width'] * $d['height'] * 100, 1) : 3.5;
                $c_score = isset($d['confidence']) ? round($d['confidence'] * 100) : round($conf * 100);

                $breakdown[] = [
                    'id' => $idx + 1,
                    'type' => $lbl,
                    'surface_coverage' => $coverage,
                    'confidence' => $c_score,
                    'box' => $box
                ];
            }

            $img = $sr['image_url'] ?? '';
            $uid = $sr['user_id'] ?? 'citizen';
            $uname = $sr['reported_by'] ?? 'Citizen User';
            $dev = 'Android YOLOv8 Mobile';
            $created = $sr['created_at'] ?? date('Y-m-d H:i:s');

            $upsert_stmt->execute([
                ':id' => $rep_id,
                ':title' => $title,
                ':severity' => $sev,
                ':status' => $st,
                ':latitude' => $lat,
                ':longitude' => $lng,
                ':road_name' => $road,
                ':confidence' => $conf,
                ':defects_count' => $def_count,
                ':hazards_breakdown' => json_encode($breakdown),
                ':image_url' => $img,
                ':user_id' => $uid,
                ':user_name' => $uname,
                ':device_model' => $dev,
                ':reported_at' => $created
            ]);
        }

        // Purge any dummy or removed records so dashboard shows ONLY real user uploads
        $valid_ids = array_filter(array_map(function($x) { return $x['id'] ?? null; }, $supabase_reports));
        if (!empty($valid_ids)) {
            $in_placeholders = implode(',', array_fill(0, count($valid_ids), '?'));
            $clean_stmt = $db->prepare("DELETE FROM pothole_reports WHERE id NOT IN ($in_placeholders)");
            $clean_stmt->execute(array_values($valid_ids));
        }
    } else {
        // Also ensure dummy test records are removed even if offline
        $db->exec("DELETE FROM pothole_reports WHERE id IN ('RPT-DHAKA-MIRPUR-001', 'RPT-APP-USER-002', 'RPT-APP-USER-003', 'RPT-APP-USER-004', 'RPT-1792217799588')");
    }

    // 3. Query merged database from SQLite (which now has all Supabase records + authority notes)
    $conditions = [];
    $params = [];

    if ($status_filter !== 'all' && !empty($status_filter)) {
        if ($status_filter === 'reported' || $status_filter === 'detected') {
            $conditions[] = "LOWER(status) IN ('reported', 'detected')";
        } elseif ($status_filter === 'assigned' || $status_filter === 'in_progress') {
            $conditions[] = "LOWER(status) IN ('assigned', 'in_progress', 'under_repair')";
        } elseif ($status_filter === 'resolved' || $status_filter === 'verified') {
            $conditions[] = "LOWER(status) IN ('resolved', 'verified')";
        } else {
            $conditions[] = "LOWER(status) = :status";
            $params[':status'] = $status_filter;
        }
    }

    if ($severity_filter !== 'ALL' && !empty($severity_filter)) {
        $conditions[] = "UPPER(severity) = :severity";
        $params[':severity'] = $severity_filter;
    }

    if (!empty($search)) {
        $conditions[] = "(id LIKE :search OR title LIKE :search OR road_name LIKE :search OR user_name LIKE :search)";
        $params[':search'] = '%' . $search . '%';
    }

    $where_sql = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';
    $sql = "SELECT * FROM pothole_reports {$where_sql} ORDER BY reported_at DESC";

    $stmt = $db->prepare($sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->execute();
    $reports = $stmt->fetchAll();

    // Format output
    $formatted = array_map(function($r) {
        if (!empty($r['hazards_breakdown']) && is_string($r['hazards_breakdown'])) {
            $r['hazards_breakdown'] = json_decode($r['hazards_breakdown'], true);
        }
        $r['latitude'] = floatval($r['latitude']);
        $r['longitude'] = floatval($r['longitude']);
        $r['confidence_pct'] = round(floatval($r['confidence']) * 100, 1);
        return $r;
    }, $reports);

    // Compute summary stats
    $stats_stmt = $db->query("
        SELECT 
            COUNT(*) as total_count,
            COUNT(CASE WHEN UPPER(severity) IN ('HIGH', 'CRITICAL') THEN 1 END) as high_severity_count,
            COUNT(CASE WHEN LOWER(status) IN ('reported', 'detected') THEN 1 END) as pending_count,
            COUNT(CASE WHEN LOWER(status) IN ('assigned', 'in_progress', 'under_repair', 'investigating') THEN 1 END) as in_progress_count,
            COUNT(CASE WHEN LOWER(status) IN ('resolved', 'verified') THEN 1 END) as resolved_count,
            COUNT(DISTINCT user_name) as total_users_count,
            AVG(confidence) as avg_confidence
        FROM pothole_reports
    ");
    $stats = $stats_stmt->fetch() ?: [];

    echo json_encode([
        'success' => true,
        'source' => !empty($supabase_reports) ? 'supabase_cloud' : 'local_cache',
        'stats' => [
            'total' => intval($stats['total_count'] ?? count($formatted)),
            'high_severity' => intval($stats['high_severity_count'] ?? 0),
            'pending' => intval($stats['pending_count'] ?? 0),
            'in_progress' => intval($stats['in_progress_count'] ?? 0),
            'resolved' => intval($stats['resolved_count'] ?? 0),
            'total_users' => max(1, intval($stats['total_users_count'] ?? 1)),
            'avg_confidence' => round(floatval($stats['avg_confidence'] ?? 0) * 100, 1)
        ],
        'count' => count($formatted),
        'data' => $formatted
    ]);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
