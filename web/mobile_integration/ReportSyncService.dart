import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// ReportSyncService
/// Integrates the Amar Path Flutter Android App with the PHP Website Database
class ReportSyncService {
  // Replace with your Authority Server IP or domain (e.g. http://192.168.0.107:8000 or your live URL)
  static String serverBaseUrl = "http://192.168.0.107:8000";

  /// Uploads a single DamageReport to the central website database in real-time
  static Future<bool> uploadDamageReport({
    required String id,
    required String damageType,
    required String severity,
    required double latitude,
    required double longitude,
    String? address,
    required DateTime timestamp,
    String status = 'reported',
    double? confidenceScore,
    String? reportedBy,
    String? deviceModel,
    double? damageAreaSqM,
    String? notes,
    String? imagePath,
    double? crackWidthMm,
    double? estimatedDepthCm,
    String? detections,
    double? bboxLeft,
    double? bboxTop,
    double? bboxRight,
    double? bboxBottom,
    int? imageWidth,
    int? imageHeight,
  }) async {
    try {
      final uri = Uri.parse("$serverBaseUrl/api/report_hazard.php");
      final request = http.MultipartRequest('POST', uri);

      // Core Detection Fields
      request.fields['id'] = id;
      request.fields['damageType'] = damageType;
      request.fields['severity'] = severity.toUpperCase();
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      request.fields['address'] = address ?? '';
      request.fields['timestamp'] = timestamp.toIso8601String();
      request.fields['status'] = status;
      request.fields['confidenceScore'] = (confidenceScore ?? 0.85).toString();

      // Genuine User & Device Info
      request.fields['reportedBy'] = reportedBy ?? 'App User';
      request.fields['user_name'] = reportedBy ?? 'App User';
      request.fields['device_model'] = deviceModel ?? 'Android Phone';

      // Physical Metrics
      if (damageAreaSqM != null) request.fields['damageAreaSqM'] = damageAreaSqM.toString();
      if (crackWidthMm != null) request.fields['crackWidthMm'] = crackWidthMm.toString();
      if (estimatedDepthCm != null) request.fields['estimatedDepthCm'] = estimatedDepthCm.toString();
      if (notes != null) request.fields['notes'] = notes;

      // Bounding Box Coordinates
      if (bboxLeft != null) request.fields['bbox_left'] = bboxLeft.toString();
      if (bboxTop != null) request.fields['bbox_top'] = bboxTop.toString();
      if (bboxRight != null) request.fields['bbox_right'] = bboxRight.toString();
      if (bboxBottom != null) request.fields['bbox_bottom'] = bboxBottom.toString();
      if (imageWidth != null) request.fields['imageWidth'] = imageWidth.toString();
      if (imageHeight != null) request.fields['imageHeight'] = imageHeight.toString();
      if (detections != null) request.fields['detections'] = detections;

      // Attach Captured Camera Photo if present on phone disk
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resJson = jsonDecode(response.body);
        print("[AmarPath] Hazard synced to server: ${resJson['message']}");
        return true;
      } else {
        print("[AmarPath] Server returned error: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("[AmarPath] Network sync failed (will retry later): $e");
      return false;
    }
  }

  /// Batch syncs multiple reports from the local SQLite database to the website database
  static Future<int> batchSyncReports(List<Map<String, dynamic>> localReports) async {
    if (localReports.isEmpty) return 0;
    try {
      final uri = Uri.parse("$serverBaseUrl/api/sync_reports.php");
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reports': localReports}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resJson = jsonDecode(response.body);
        final count = resJson['processed_count'] ?? 0;
        print("[AmarPath] Successfully batch synced $count reports to website database.");
        return count;
      }
    } catch (e) {
      print("[AmarPath] Batch sync failed: $e");
    }
    return 0;
  }

  /// Fetches nearby hazard alerts so users get real-time audio/visual warnings
  static Future<List<dynamic>> fetchNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final uri = Uri.parse(
        "$serverBaseUrl/api/hazard_alerts.php?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm"
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['alerts'] ?? [];
      }
    } catch (e) {
      print("[AmarPath] Failed to fetch alerts: $e");
    }
    return [];
  }
}
