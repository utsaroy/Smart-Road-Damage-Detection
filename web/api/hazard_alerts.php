<?php
/**
 * REST API: Hazard Alerts
 * Returns nearby detected potholes for the Android App's live proximity alert system
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../config/database.php';

try {
    $db = Database::getConnection();

    $lat = isset($_GET['latitude']) ? floatval($_GET['latitude']) : (isset($_GET['lat']) ? floatval($_GET['lat']) : null);
    $lng = isset($_GET['longitude']) ? floatval($_GET['longitude']) : (isset($_GET['lng']) ? floatval($_GET['lng']) : null);
    $radius_km = floatval($_GET['radius_km'] ?? $_GET['radius'] ?? 10.0);

    $sql = "SELECT id, title, severity, latitude, longitude, road_name, damage_type, reported_at, status 
            FROM pothole_reports 
            WHERE status != 'resolved' 
            ORDER BY reported_at DESC 
            LIMIT 50";
    
    $stmt = $db->query($sql);
    $reports = $stmt->fetchAll();

    $alerts = [];
    foreach ($reports as $r) {
        $distance_m = null;
        if ($lat !== null && $lng !== null) {
            // Haversine formula
            $earth_radius = 6371000; // meters
            $dLat = deg2rad($r['latitude'] - $lat);
            $dLng = deg2rad($r['longitude'] - $lng);
            $a = sin($dLat / 2) * sin($dLat / 2) +
                 cos(deg2rad($lat)) * cos(deg2rad($r['latitude'])) *
                 sin($dLng / 2) * sin($dLng / 2);
            $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
            $distance_m = round($earth_radius * $c, 1);

            if ($distance_m > ($radius_km * 1000)) {
                continue; // Outside requested radius
            }
        }

        $alerts[] = [
            'id' => $r['id'],
            'title' => $r['title'],
            'severity' => $r['severity'],
            'distanceMeters' => $distance_m,
            'address' => $r['road_name'],
            'damageType' => $r['damage_type'] ?? 'Pothole',
            'lastReported' => $r['reported_at'],
            'latitude' => floatval($r['latitude']),
            'longitude' => floatval($r['longitude']),
            'isActive' => 1
        ];
    }

    echo json_encode([
        'success' => true,
        'count' => count($alerts),
        'alerts' => $alerts
    ], JSON_PRETTY_PRINT);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
