<?php
/**
 * REST API: Upazilla-wise Pothole Density Ratio & Analytics
 * Calculates pothole density ratio across Bangladesh Upazillas in descending order
 * Supports multi-tier cascading filtering: Division -> District -> Upazilla
 */

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/../config/database.php';
require_once __DIR__ . '/../includes/geo_helper.php';

try {
    $db = Database::getConnection();

    // Query parameters
    $division_filter = trim($_GET['division'] ?? 'all');
    $district_filter = trim($_GET['district'] ?? 'all');
    $upazilla_filter = trim($_GET['upazilla'] ?? 'all');
    $search_query = trim($_GET['search'] ?? '');

    // 1. First ensure all records in SQLite have division and upazilla populated
    $unresolved = $db->query("SELECT id, latitude, longitude, road_name, address, district FROM pothole_reports WHERE upazilla IS NULL OR division IS NULL")->fetchAll();
    if (!empty($unresolved)) {
        $update_stmt = $db->prepare("UPDATE pothole_reports SET division = :division, district = :district, upazilla = :upazilla WHERE id = :id");
        foreach ($unresolved as $row) {
            $lat = isset($row['latitude']) ? floatval($row['latitude']) : null;
            $lng = isset($row['longitude']) ? floatval($row['longitude']) : null;
            $addr = ($row['road_name'] ?? '') . ' ' . ($row['address'] ?? '');
            $geo = BangladeshGeo::resolveLocation($lat, $lng, $addr, $row['district'] ?? '');
            $update_stmt->execute([
                ':division' => $geo['division'],
                ':district' => $geo['district'],
                ':upazilla' => $geo['upazilla'],
                ':id' => $row['id']
            ]);
        }
    }

    // 2. Total Potholes across entire DB
    $total_all_stmt = $db->query("SELECT COUNT(*) FROM pothole_reports");
    $total_countrywide = intval($total_all_stmt->fetchColumn() ?: 0);

    // 3. Build filtered condition
    $conditions = [];
    $params = [];

    if ($division_filter !== 'all' && !empty($division_filter)) {
        $conditions[] = "LOWER(division) = :division";
        $params[':division'] = strtolower($division_filter);
    }

    if ($district_filter !== 'all' && !empty($district_filter)) {
        $conditions[] = "LOWER(district) = :district";
        $params[':district'] = strtolower($district_filter);
    }

    if ($upazilla_filter !== 'all' && !empty($upazilla_filter)) {
        $conditions[] = "LOWER(upazilla) = :upazilla";
        $params[':upazilla'] = strtolower($upazilla_filter);
    }

    if (!empty($search_query)) {
        $conditions[] = "(LOWER(upazilla) LIKE :search OR LOWER(district) LIKE :search OR LOWER(division) LIKE :search)";
        $params[':search'] = '%' . strtolower($search_query) . '%';
    }

    $where_sql = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';

    // Count in filtered scope
    $count_sql = "SELECT COUNT(*) FROM pothole_reports {$where_sql}";
    $count_stmt = $db->prepare($count_sql);
    foreach ($params as $k => $v) {
        $count_stmt->bindValue($k, $v);
    }
    $count_stmt->execute();
    $total_in_scope = intval($count_stmt->fetchColumn() ?: 0);

    // 4. Aggregated Upazilla Query: Group by Upazilla, District, Division
    $agg_sql = "
        SELECT 
            COALESCE(upazilla, 'Unknown Upazilla') as upazilla,
            COALESCE(district, 'Unknown District') as district,
            COALESCE(division, 'Unknown Division') as division,
            COUNT(*) as total_hazards,
            SUM(CASE WHEN UPPER(severity) = 'CRITICAL' THEN 1 ELSE 0 END) as critical_count,
            SUM(CASE WHEN UPPER(severity) = 'HIGH' THEN 1 ELSE 0 END) as high_count,
            SUM(CASE WHEN UPPER(severity) = 'MEDIUM' THEN 1 ELSE 0 END) as medium_count,
            SUM(CASE WHEN UPPER(severity) = 'LOW' THEN 1 ELSE 0 END) as low_count,
            SUM(CASE WHEN LOWER(status) IN ('reported', 'detected') THEN 1 ELSE 0 END) as pending_count,
            SUM(CASE WHEN LOWER(status) IN ('assigned', 'in_progress', 'under_repair') THEN 1 ELSE 0 END) as in_progress_count,
            SUM(CASE WHEN LOWER(status) IN ('resolved', 'verified') THEN 1 ELSE 0 END) as resolved_count,
            AVG(CASE WHEN confidence > 0 THEN confidence ELSE 0.85 END) as avg_confidence,
            AVG(latitude) as centroid_lat,
            AVG(longitude) as centroid_lng,
            GROUP_CONCAT(DISTINCT road_name) as sample_roads
        FROM pothole_reports
        {$where_sql}
        GROUP BY upazilla, district, division
        ORDER BY total_hazards DESC
    ";

    $stmt = $db->prepare($agg_sql);
    foreach ($params as $k => $v) {
        $stmt->bindValue($k, $v);
    }
    $stmt->execute();
    $rows = $stmt->fetchAll();

    // Determine max hazards in a single upazilla for relative bar normalization
    $max_hazards = 0;
    foreach ($rows as $r) {
        if ($r['total_hazards'] > $max_hazards) {
            $max_hazards = $r['total_hazards'];
        }
    }

    $ranking_list = [];
    $reference_total = max(1, $total_countrywide); // Base density percentage on total detected hazards in DB
    $processed_keys = [];

    // 4.1 Process upazillas that have active records in DB
    foreach ($rows as $row) {
        $count = intval($row['total_hazards']);
        $pct = round(($count / $reference_total) * 100, 1);
        $relative_pct = $max_hazards > 0 ? round(($count / $max_hazards) * 100, 1) : 0;

        if ($pct >= 30.0) {
            $density_grade = 'Critical Hotspot';
            $density_color = 'rose';
            $urgency = 'Immediate Emergency Patch (24H)';
        } elseif ($pct >= 15.0) {
            $density_grade = 'High Density';
            $density_color = 'orange';
            $urgency = 'High Priority Repair (3-5 Days)';
        } elseif ($pct >= 5.0) {
            $density_grade = 'Moderate Density';
            $density_color = 'amber';
            $urgency = 'Routine Maintenance (2 Weeks)';
        } else {
            $density_grade = 'Low Density';
            $density_color = 'emerald';
            $urgency = 'Routine Inspection';
        }

        // Fetch distinct roads specifically for this upazilla
        $road_stmt = $db->prepare("SELECT DISTINCT road_name FROM pothole_reports WHERE upazilla = :upazilla AND district = :district AND road_name IS NOT NULL AND road_name != '' LIMIT 5");
        $road_stmt->execute([':upazilla' => $row['upazilla'], ':district' => $row['district']]);
        $roads = $road_stmt->fetchAll(PDO::FETCH_COLUMN) ?: [];

        $key = strtolower(trim($row['division'])) . '|' . strtolower(trim($row['district'])) . '|' . strtolower(trim($row['upazilla']));
        $processed_keys[$key] = true;

        $ranking_list[] = [
            'rank' => 0,
            'upazilla' => $row['upazilla'],
            'district' => $row['district'],
            'division' => $row['division'],
            'total_hazards' => $count,
            'density_percentage' => $pct,
            'density_relative_pct' => $relative_pct,
            'critical_count' => intval($row['critical_count']),
            'high_count' => intval($row['high_count']),
            'medium_count' => intval($row['medium_count']),
            'low_count' => intval($row['low_count']),
            'pending_count' => intval($row['pending_count']),
            'in_progress_count' => intval($row['in_progress_count']),
            'resolved_count' => intval($row['resolved_count']),
            'avg_confidence' => round(floatval($row['avg_confidence']) * 100, 1),
            'centroid_lat' => floatval($row['centroid_lat']),
            'centroid_lng' => floatval($row['centroid_lng']),
            'density_grade' => $density_grade,
            'density_color' => $density_color,
            'urgency' => $urgency,
            'sample_roads' => array_values($roads)
        ];
    }

    // 4.2 If filtering by District/Upazilla or Searching, include matching Upazillas that have 0 records
    $hierarchy = BangladeshGeo::getHierarchy();
    $has_specific_filter = (!empty($search_query) || $upazilla_filter !== 'all' || $district_filter !== 'all' || $division_filter !== 'all');

    if ($has_specific_filter) {
        foreach ($hierarchy as $divName => $districts) {
            if ($division_filter !== 'all' && strcasecmp($division_filter, $divName) !== 0) {
                continue;
            }
            foreach ($districts as $distName => $upazillas) {
                if ($district_filter !== 'all' && strcasecmp($district_filter, $distName) !== 0) {
                    continue;
                }
                foreach ($upazillas as $upaName) {
                    if ($upazilla_filter !== 'all' && strcasecmp($upazilla_filter, $upaName) !== 0) {
                        continue;
                    }
                    if (!empty($search_query)) {
                        $q = strtolower($search_query);
                        if (strpos(strtolower($upaName), $q) === false && 
                            strpos(strtolower($distName), $q) === false && 
                            strpos(strtolower($divName), $q) === false) {
                            continue;
                        }
                    }

                    $key = strtolower(trim($divName)) . '|' . strtolower(trim($distName)) . '|' . strtolower(trim($upaName));
                    if (!isset($processed_keys[$key])) {
                        $processed_keys[$key] = true;
                        $coords = BangladeshGeo::getCoordinatesForUpazilla($upaName, $distName);

                        $ranking_list[] = [
                            'rank' => 0,
                            'upazilla' => $upaName,
                            'district' => $distName,
                            'division' => $divName,
                            'total_hazards' => 0,
                            'density_percentage' => 0.0,
                            'density_relative_pct' => 0.0,
                            'critical_count' => 0,
                            'high_count' => 0,
                            'medium_count' => 0,
                            'low_count' => 0,
                            'pending_count' => 0,
                            'in_progress_count' => 0,
                            'resolved_count' => 0,
                            'avg_confidence' => 0.0,
                            'centroid_lat' => floatval($coords['lat']),
                            'centroid_lng' => floatval($coords['lng']),
                            'density_grade' => 'Zero Defects (Clear)',
                            'density_color' => 'emerald',
                            'urgency' => 'Safe Pavement - Routine Monitoring',
                            'sample_roads' => ['No active road hazards reported']
                        ];
                    }
                }
            }
        }
    }

    // 4.3 Sort: Descending by total_hazards, then ascending by upazilla name
    usort($ranking_list, function($a, $b) {
        if ($b['total_hazards'] !== $a['total_hazards']) {
            return $b['total_hazards'] <=> $a['total_hazards'];
        }
        return strcasecmp($a['upazilla'], $b['upazilla']);
    });

    // Assign sequential ranks
    $rank = 1;
    foreach ($ranking_list as &$item) {
        $item['rank'] = $rank++;
    }
    unset($item);

    // 4.4 Particular Upazilla Detail ONLY when an Upazilla is explicitly selected via dropdown, NOT when searching
    $particular_stat = null;
    if ($upazilla_filter !== 'all' && !empty($upazilla_filter) && empty($search_query) && count($ranking_list) > 0) {
        $particular_stat = $ranking_list[0];
    }

    echo json_encode([
        'success' => true,
        'totals' => [
            'countrywide' => $total_countrywide,
            'in_scope' => $total_in_scope,
            'total_upazillas_affected' => count($ranking_list)
        ],
        'filters' => [
            'division' => $division_filter,
            'district' => $district_filter,
            'upazilla' => $upazilla_filter,
            'search' => $search_query
        ],
        'hierarchy' => BangladeshGeo::getHierarchy(),
        'ranking' => $ranking_list,
        'particular_stat' => $particular_stat
    ], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);

} catch (Throwable $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
