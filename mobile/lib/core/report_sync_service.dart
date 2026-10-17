import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'database_service.dart';
import 'models.dart';

/// ReportSyncService
/// Automatically bridges the Amar Path Flutter Android app with the central Road Authority Website Database.
/// Every detected road hazard is synchronized in real time in the background.
class ReportSyncService {
  static final ReportSyncService instance = ReportSyncService._internal();

  ReportSyncService._internal();

  // Central Authority Server Base URL
  // Can be configured to local Wi-Fi IP, Public Tunnel, or live domain
  String serverBaseUrl = 'http://192.168.0.107:8000';

  /// Initializes the sync service and reads custom server URL from app settings if configured
  Future<void> init() async {
    try {
      final savedUrl = await DatabaseService.instance.getSetting('authorityServerUrl');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        serverBaseUrl = savedUrl;
      }
      debugPrint('[ReportSyncService] Configured with server URL: $serverBaseUrl');
    } catch (e) {
      debugPrint('[ReportSyncService] Init error: $e');
    }
  }

  /// Sets and persists a new server URL (e.g. from the Profile/Settings screen)
  Future<void> setServerUrl(String url) async {
    serverBaseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await DatabaseService.instance.saveSetting('authorityServerUrl', serverBaseUrl);
    debugPrint('[ReportSyncService] Updated server URL: $serverBaseUrl');
  }

  /// Automatically uploads a newly detected DamageReport to the website database in real time
  Future<bool> uploadDamageReport(DamageReport report) async {
    try {
      final uri = Uri.parse('$serverBaseUrl/api/report_hazard.php');
      final request = http.MultipartRequest('POST', uri);

      // Detection & Physical Attributes
      request.fields['id'] = report.id;
      request.fields['damageType'] = report.damageType;
      request.fields['severity'] = report.severity.toUpperCase();
      request.fields['latitude'] = report.latitude.toString();
      request.fields['longitude'] = report.longitude.toString();
      request.fields['address'] = report.address;
      request.fields['timestamp'] = report.timestamp.toIso8601String();
      request.fields['status'] = report.status;
      request.fields['confidenceScore'] = report.confidenceScore.toString();

      // User & Device Identity
      final reporter = (report.reportedBy.isNotEmpty && report.reportedBy.toLowerCase() != 'you')
          ? report.reportedBy
          : 'App User';
      request.fields['reportedBy'] = reporter;
      request.fields['user_name'] = reporter;

      String deviceModel = 'Android Phone';
      try {
        deviceModel = '${Platform.operatingSystem} (${Platform.operatingSystemVersion.split(' ')[0]})';
      } catch (_) {}
      request.fields['device_model'] = deviceModel;

      // Metric & Bounding Details
      if (report.damageAreaSqM != null) {
        request.fields['damageAreaSqM'] = report.damageAreaSqM.toString();
      }
      if (report.crackWidthMm != null) {
        request.fields['crackWidthMm'] = report.crackWidthMm.toString();
      }
      if (report.estimatedDepthCm != null) {
        request.fields['estimatedDepthCm'] = report.estimatedDepthCm.toString();
      }
      if (report.notes != null) {
        request.fields['notes'] = report.notes!;
      }
      if (report.boundingBox != null) {
        request.fields['bbox_left'] = report.boundingBox!.left.toString();
        request.fields['bbox_top'] = report.boundingBox!.top.toString();
        request.fields['bbox_right'] = report.boundingBox!.right.toString();
        request.fields['bbox_bottom'] = report.boundingBox!.bottom.toString();
      }
      if (report.imageWidth != null) {
        request.fields['imageWidth'] = report.imageWidth.toString();
      }
      if (report.imageHeight != null) {
        request.fields['imageHeight'] = report.imageHeight.toString();
      }
      if (report.detections.isNotEmpty) {
        request.fields['detections'] = jsonEncode(
          report.detections.map((d) => d.toMap()).toList(),
        );
      }

      // Attach Captured Camera Photo if present on phone disk
      if (report.imagePath != null && report.imagePath!.isNotEmpty) {
        final file = File(report.imagePath!);
        if (await file.exists()) {
          request.files.add(await http.MultipartFile.fromPath('image', report.imagePath!));
        }
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ReportSyncService] Report ${report.id} uploaded to website DB successfully.');
        return true;
      } else {
        debugPrint('[ReportSyncService] Server rejected upload (${response.statusCode}): ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[ReportSyncService] Network error uploading report: $e');
      return false;
    }
  }

  /// Synchronizes all locally accumulated SQLite reports in batch (e.g. on app launch or reconnect)
  Future<int> syncAllLocalReports() async {
    try {
      final reports = await DatabaseService.instance.getAllReports();
      if (reports.isEmpty) return 0;

      final list = reports.map((r) => r.toMap()).toList();
      final uri = Uri.parse('$serverBaseUrl/api/sync_reports.php');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reports': list}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = jsonDecode(response.body);
        final count = res['processed_count'] ?? 0;
        debugPrint('[ReportSyncService] Successfully synced $count reports to website database.');
        return count;
      }
    } catch (e) {
      debugPrint('[ReportSyncService] Batch sync error: $e');
    }
    return 0;
  }

  /// Fetches nearby hazard alerts from the central database so the driver gets notified
  Future<List<HazardAlert>> fetchNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final uri = Uri.parse(
        '$serverBaseUrl/api/hazard_alerts.php?latitude=$latitude&longitude=$longitude&radius_km=$radiusKm',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        final list = res['alerts'] as List? ?? [];
        final alerts = <HazardAlert>[];

        for (final item in list) {
          final alert = HazardAlert(
            id: item['id'] ?? 'HZD-${DateTime.now().millisecondsSinceEpoch}',
            title: item['title'] ?? 'Road Hazard Ahead',
            severity: item['severity'] ?? 'High',
            distanceMeters: (item['distanceMeters'] as num?)?.toDouble() ?? 0.0,
            address: item['address'] ?? 'Survey Zone',
            damageType: item['damageType'] ?? 'Pothole',
            lastReported: DateTime.tryParse(item['lastReported'] ?? '') ?? DateTime.now(),
            latitude: (item['latitude'] as num).toDouble(),
            longitude: (item['longitude'] as num).toDouble(),
            isActive: true,
          );
          alerts.add(alert);
          // Persist in local database for offline driving warning
          await DatabaseService.instance.insertAlert(alert);
        }

        return alerts;
      }
    } catch (e) {
      debugPrint('[ReportSyncService] Error fetching nearby alerts: $e');
    }
    return [];
  }
}
