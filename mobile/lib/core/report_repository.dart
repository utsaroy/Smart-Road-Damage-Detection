import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'models.dart';

/// Repository managing reports, alerts, user stats, and app settings.
/// Uses in-memory state with ChangeNotifier for reactive UI updates across screens.
class ReportRepository extends ChangeNotifier {
  static final ReportRepository instance = ReportRepository._internal();

  ReportRepository._internal() {
    _initializeSampleData();
  }

  late List<DamageReport> _reports;
  late List<HazardAlert> _alerts;
  late UserStats _stats;

  // Settings
  double _alertRadius = 300.0;
  bool _soundAlertsEnabled = true;
  bool _vibrationEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _criticalOnlyAlerts = false;
  final String _aiModel = 'best.tflite (YOLOv8 On-Device)';
  bool _autoGpsTagging = true;
  bool _highResCapture = true;

  // Getters
  List<DamageReport> get reports => List.unmodifiable(_reports);
  List<HazardAlert> get alerts => List.unmodifiable(_alerts);
  UserStats get stats => _stats;

  double get alertRadius => _alertRadius;
  bool get soundAlertsEnabled => _soundAlertsEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get pushNotificationsEnabled => _pushNotificationsEnabled;
  bool get criticalOnlyAlerts => _criticalOnlyAlerts;
  String get aiModel => _aiModel;
  bool get autoGpsTagging => _autoGpsTagging;
  bool get highResCapture => _highResCapture;

  List<DamageReport> get userCaptures =>
      _reports.where((r) => r.reportedBy.toLowerCase() == 'you').toList();

  List<DamageReport> get detectedReports =>
      _reports.where((r) => r.status.toLowerCase() != 'pending').toList();

  List<HazardAlert> get alertsInRadius {
    return _alerts.where((a) {
      final matchesRadius = a.distanceMeters <= _alertRadius;
      if (_criticalOnlyAlerts) {
        return matchesRadius && (a.severity == 'Critical' || a.severity == 'High');
      }
      return matchesRadius;
    }).toList();
  }

  /// Calculates geodesic distance between two coordinates in meters (Haversine formula)
  static double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double p = 0.017453292519943295; // Pi / 180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(math.max(0.0, a))); // 2 * R * 1000 m
  }

  /// Returns unified map hazard items combining detected reports and active alerts,
  /// with live distances calculated from userLocation if provided.
  List<MapHazardItem> getMapHazardItems([LatLng? userLocation]) {
    final items = <MapHazardItem>[];
    final seenReportIds = <String>{};

    // 1. Add all detected road damage reports
    for (final report in detectedReports) {
      seenReportIds.add(report.id);
      seenReportIds.add('HZD-${report.id}');
      final isUser = report.imagePath != null || report.reportedBy.toLowerCase() == 'you';
      double dist = 0.0;
      if (userLocation != null) {
        dist = distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          report.latitude,
          report.longitude,
        );
      }

      items.add(
        MapHazardItem(
          id: report.id,
          title: '${report.damageType} Detected',
          damageType: report.damageType,
          severity: report.severity,
          latitude: report.latitude,
          longitude: report.longitude,
          address: report.address,
          timestamp: report.timestamp,
          confidence: report.confidenceScore,
          imagePath: report.imagePath,
          isUserCapture: isUser,
          sourceReport: report,
          distanceMeters: dist,
        ),
      );
    }

    // 2. Add alerts that are not already from reports
    for (final alert in _alerts) {
      if (!seenReportIds.contains(alert.id)) {
        double dist = alert.distanceMeters;
        if (userLocation != null) {
          dist = distanceBetween(
            userLocation.latitude,
            userLocation.longitude,
            alert.latitude,
            alert.longitude,
          );
        }

        items.add(
          MapHazardItem(
            id: alert.id,
            title: alert.title,
            damageType: alert.damageType,
            severity: alert.severity,
            latitude: alert.latitude,
            longitude: alert.longitude,
            address: alert.address,
            timestamp: alert.lastReported,
            confidence: 0.90,
            imagePath: null,
            isUserCapture: false,
            sourceReport: null,
            distanceMeters: dist,
          ),
        );
      }
    }

    return items;
  }

  /// Returns hazards & detections near user location within alert radius,
  /// with user's real captures always prioritized at the top.
  List<MapHazardItem> getNearbyHazards(LatLng userLocation) {
    final all = getMapHazardItems(userLocation);
    final filtered = all.where((item) {
      // User's own captures are always included
      if (item.isUserCapture) return true;
      final matchesRadius = item.distanceMeters <= _alertRadius;
      if (_criticalOnlyAlerts) {
        return matchesRadius && (item.severity == 'Critical' || item.severity == 'High');
      }
      return matchesRadius;
    }).toList();

    // Sort: user captures first, then by nearest distance
    filtered.sort((a, b) {
      if (a.isUserCapture && !b.isUserCapture) return -1;
      if (!a.isUserCapture && b.isUserCapture) return 1;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });

    return filtered;
  }

  void _initializeSampleData() {
    final now = DateTime.now();

    _reports = [
      DamageReport(
        id: 'RPT-1042',
        damageType: 'Pothole',
        severity: 'Critical',
        latitude: 23.8118,
        longitude: 90.4132,
        address: 'Mirpur Road, Section 10',
        timestamp: now.subtract(const Duration(minutes: 18)),
        status: 'detected',
        confidenceScore: 0.94,
        reportedBy: 'You',
        damageAreaSqM: 0.42,
        notes: 'Deep road surface cavity with sharp broken edges. Immediate asphalt patching recommended.',
        crackWidthMm: 280.0,
        estimatedDepthCm: 6.5,
        boundingBox: const Rect.fromLTWH(0.22, 0.30, 0.48, 0.42),
      ),
      DamageReport(
        id: 'RPT-1041',
        damageType: 'Longitudinal Crack',
        severity: 'High',
        latitude: 23.8092,
        longitude: 90.4115,
        address: 'Satmasjid Road, Dhanmondi',
        timestamp: now.subtract(const Duration(hours: 2, minutes: 14)),
        status: 'detected',
        confidenceScore: 0.89,
        reportedBy: 'You',
        damageAreaSqM: 0.28,
        notes: 'Linear surface fracture running parallel to wheel path. Crack seal required to prevent water infiltration.',
        crackWidthMm: 18.0,
        estimatedDepthCm: 3.2,
        boundingBox: const Rect.fromLTWH(0.42, 0.12, 0.18, 0.76),
      ),
      DamageReport(
        id: 'RPT-1040',
        damageType: 'Alligator Crack',
        severity: 'Critical',
        latitude: 23.8130,
        longitude: 90.4148,
        address: 'Airport Road, Kurmitola',
        timestamp: now.subtract(const Duration(hours: 5)),
        status: 'processing',
        confidenceScore: 0.91,
        reportedBy: 'You',
        damageAreaSqM: 0.85,
        notes: 'Interconnected fatigue cracking network indicating sub-base structural failure.',
        crackWidthMm: 12.0,
        estimatedDepthCm: 4.8,
        boundingBox: const Rect.fromLTWH(0.18, 0.22, 0.62, 0.54),
      ),
      DamageReport(
        id: 'RPT-1039',
        damageType: 'Transverse Crack',
        severity: 'Medium',
        latitude: 23.8080,
        longitude: 90.4100,
        address: 'Road 11, Banani',
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        status: 'resolved',
        confidenceScore: 0.85,
        reportedBy: 'Field Inspector',
        damageAreaSqM: 0.15,
        notes: 'Thermal contraction crack repaired with polymer-modified bitumen.',
        crackWidthMm: 8.5,
        estimatedDepthCm: 2.1,
        boundingBox: const Rect.fromLTWH(0.12, 0.46, 0.76, 0.18),
      ),
      DamageReport(
        id: 'RPT-1038',
        damageType: 'Pothole',
        severity: 'Medium',
        latitude: 23.8142,
        longitude: 90.4110,
        address: 'Mohakhali Flyover Approach',
        timestamp: now.subtract(const Duration(days: 2)),
        status: 'resolved',
        confidenceScore: 0.82,
        reportedBy: 'You',
        damageAreaSqM: 0.19,
        notes: 'Surface spalling sealed during routine maintenance.',
        crackWidthMm: 140.0,
        estimatedDepthCm: 3.0,
        boundingBox: const Rect.fromLTWH(0.32, 0.38, 0.36, 0.34),
      ),
    ];

    _alerts = [
      HazardAlert(
        id: 'HZD-01',
        title: 'Severe Pothole Cluster',
        severity: 'Critical',
        distanceMeters: 65,
        address: 'Mirpur Road, Near Section 10',
        damageType: 'Pothole',
        lastReported: now.subtract(const Duration(minutes: 10)),
        latitude: 23.8118,
        longitude: 90.4132,
      ),
      HazardAlert(
        id: 'HZD-02',
        title: 'Deep Longitudinal Crack',
        severity: 'High',
        distanceMeters: 145,
        address: 'Satmasjid Road, Dhanmondi',
        damageType: 'Longitudinal Crack',
        lastReported: now.subtract(const Duration(hours: 1)),
        latitude: 23.8092,
        longitude: 90.4115,
      ),
      HazardAlert(
        id: 'HZD-03',
        title: 'Alligator Fatigue Fractures',
        severity: 'Critical',
        distanceMeters: 280,
        address: 'Airport Road, Kurmitola',
        damageType: 'Alligator Crack',
        lastReported: now.subtract(const Duration(hours: 4)),
        latitude: 23.8130,
        longitude: 90.4148,
      ),
      HazardAlert(
        id: 'HZD-04',
        title: 'Transverse Surface Crack',
        severity: 'Medium',
        distanceMeters: 360,
        address: 'Road 11, Banani',
        damageType: 'Transverse Crack',
        lastReported: now.subtract(const Duration(hours: 8)),
        latitude: 23.8080,
        longitude: 90.4100,
      ),
    ];

    _recalculateStats();
  }

  void _recalculateStats() {
    final resolvedCount =
        _reports.where((r) => r.status.toLowerCase() == 'resolved').length;
    final detectedCount =
        _reports.where((r) => r.status.toLowerCase() == 'detected').length;
    final pendingCount = _reports
        .where(
          (r) =>
              r.status.toLowerCase() == 'pending' ||
              r.status.toLowerCase() == 'processing',
        )
        .length;

    _stats = UserStats(
      totalCaptures: _reports.length,
      detectedDamages: detectedCount + resolvedCount,
      pendingProcessing: pendingCount,
      resolvedIssues: resolvedCount,
      alertsTriggered: _alerts.length,
      kmCovered: 18.4,
    );
  }

  void setAlertRadius(double radius) {
    _alertRadius = radius.clamp(10.0, 500.0);
    notifyListeners();
  }

  void toggleSoundAlerts(bool val) {
    _soundAlertsEnabled = val;
    notifyListeners();
  }

  void toggleVibration(bool val) {
    _vibrationEnabled = val;
    notifyListeners();
  }

  void togglePushNotifications(bool val) {
    _pushNotificationsEnabled = val;
    notifyListeners();
  }

  void toggleCriticalOnly(bool val) {
    _criticalOnlyAlerts = val;
    notifyListeners();
  }

  void toggleAutoGps(bool val) {
    _autoGpsTagging = val;
    notifyListeners();
  }

  void toggleHighRes(bool val) {
    _highResCapture = val;
    notifyListeners();
  }

  Future<void> addReport(DamageReport report) async {
    _reports.insert(0, report);
    _recalculateStats();
    notifyListeners();
  }

  void toggleResolve(String reportId) {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final current = _reports[idx];
      final newStatus =
          current.status.toLowerCase() == 'resolved' ? 'detected' : 'resolved';
      _reports[idx] = current.copyWith(status: newStatus);
      _recalculateStats();
      notifyListeners();
    }
  }

  void deleteReport(String reportId) {
    _reports.removeWhere((r) => r.id == reportId);
    _recalculateStats();
    notifyListeners();
  }

  void clearAllReports() {
    _reports.clear();
    _recalculateStats();
    notifyListeners();
  }
}
