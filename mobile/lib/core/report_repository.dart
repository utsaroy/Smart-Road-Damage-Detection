import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'database_service.dart';
import 'models.dart';
import 'report_sync_service.dart';

/// Repository managing reports, alerts, user stats, and app settings.
/// Uses in-memory state with ChangeNotifier for reactive UI updates across screens.
class ReportRepository extends ChangeNotifier {
  static final ReportRepository instance = ReportRepository._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  ReportRepository._internal() {
    _initializeSampleData();
    init();
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
  String _aiModel = 'best.tflite (YOLOv8 On-Device)';
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
    _reports = [];
    _alerts = [];
    _recalculateStats();
  }

  /// Hydrates the repository from the local SQLite database.
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final db = DatabaseService.instance;
      final savedReports = await db.getAllReports();
      final savedAlerts = await db.getAllAlerts();
      final savedSettings = await db.getAllSettings();

      if (savedReports.isNotEmpty) {
        _reports = savedReports;
      }

      if (savedAlerts.isNotEmpty) {
        _alerts = savedAlerts;
      } else if (savedReports.isNotEmpty) {
        // Synthesize alerts for active reports if none stored
        _alerts = savedReports
            .where((r) => r.status.toLowerCase() != 'resolved')
            .map(
              (r) => HazardAlert(
                id: 'HZD-${r.id}',
                title: '${r.severity} ${r.damageType}',
                severity: r.severity,
                distanceMeters: 0,
                address: r.address,
                damageType: r.damageType,
                lastReported: r.timestamp,
                latitude: r.latitude,
                longitude: r.longitude,
                isActive: true,
              ),
            )
            .toList();
      }

      if (savedSettings.containsKey('alertRadius')) {
        _alertRadius =
            double.tryParse(savedSettings['alertRadius']!) ?? _alertRadius;
      }
      if (savedSettings.containsKey('soundAlertsEnabled')) {
        _soundAlertsEnabled = savedSettings['soundAlertsEnabled'] == 'true';
      }
      if (savedSettings.containsKey('vibrationEnabled')) {
        _vibrationEnabled = savedSettings['vibrationEnabled'] == 'true';
      }
      if (savedSettings.containsKey('pushNotificationsEnabled')) {
        _pushNotificationsEnabled =
            savedSettings['pushNotificationsEnabled'] == 'true';
      }
      if (savedSettings.containsKey('criticalOnlyAlerts')) {
        _criticalOnlyAlerts = savedSettings['criticalOnlyAlerts'] == 'true';
      }
      if (savedSettings.containsKey('aiModel')) {
        _aiModel = savedSettings['aiModel']!;
      }
      if (savedSettings.containsKey('autoGpsTagging')) {
        _autoGpsTagging = savedSettings['autoGpsTagging'] == 'true';
      }
      if (savedSettings.containsKey('highResCapture')) {
        _highResCapture = savedSettings['highResCapture'] == 'true';
      }

      _recalculateStats();
      _isInitialized = true;
      notifyListeners();

      // Initialize sync service and sync any offline pending captures
      ReportSyncService.instance.init().then((_) {
        ReportSyncService.instance.syncAllLocalReports();
      });
    } catch (e) {
      debugPrint('[ReportRepository] Error initializing from database: $e');
    }
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
      kmCovered: 0.0,
    );
  }

  void setAlertRadius(double radius) {
    _alertRadius = radius.clamp(10.0, 500.0);
    notifyListeners();
    DatabaseService.instance.saveSetting('alertRadius', _alertRadius.toString());
  }

  void toggleSoundAlerts(bool val) {
    _soundAlertsEnabled = val;
    notifyListeners();
    DatabaseService.instance.saveSetting('soundAlertsEnabled', val.toString());
  }

  void toggleVibration(bool val) {
    _vibrationEnabled = val;
    notifyListeners();
    DatabaseService.instance.saveSetting('vibrationEnabled', val.toString());
  }

  void togglePushNotifications(bool val) {
    _pushNotificationsEnabled = val;
    notifyListeners();
    DatabaseService.instance
        .saveSetting('pushNotificationsEnabled', val.toString());
  }

  void toggleCriticalOnly(bool val) {
    _criticalOnlyAlerts = val;
    notifyListeners();
    DatabaseService.instance.saveSetting('criticalOnlyAlerts', val.toString());
  }

  void toggleAutoGps(bool val) {
    _autoGpsTagging = val;
    notifyListeners();
    DatabaseService.instance.saveSetting('autoGpsTagging', val.toString());
  }

  void toggleHighRes(bool val) {
    _highResCapture = val;
    notifyListeners();
    DatabaseService.instance.saveSetting('highResCapture', val.toString());
  }

  void setAiModel(String model) {
    _aiModel = model;
    notifyListeners();
    DatabaseService.instance.saveSetting('aiModel', model);
  }

  Future<void> addReport(DamageReport report) async {
    _reports.insert(0, report);
    HazardAlert? alert;
    if (report.status.toLowerCase() != 'resolved') {
      alert = HazardAlert(
        id: 'HZD-${report.id}',
        title: '${report.severity} ${report.damageType}',
        severity: report.severity,
        distanceMeters: 0,
        address: report.address,
        damageType: report.damageType,
        lastReported: report.timestamp,
        latitude: report.latitude,
        longitude: report.longitude,
        isActive: true,
      );
      _alerts.insert(0, alert);
    }
    _recalculateStats();
    notifyListeners();

    // Persist to local SQLite database
    await DatabaseService.instance.insertReport(report);
    if (alert != null) {
      await DatabaseService.instance.insertAlert(alert);
    }

    // Automatically sync with central website database in real time
    ReportSyncService.instance.uploadDamageReport(report);
  }

  void toggleResolve(String reportId) {
    final idx = _reports.indexWhere((r) => r.id == reportId);
    if (idx != -1) {
      final current = _reports[idx];
      final newStatus =
          current.status.toLowerCase() == 'resolved' ? 'detected' : 'resolved';
      _reports[idx] = current.copyWith(status: newStatus);

      final alertIdx = _alerts.indexWhere((a) => a.id == 'HZD-$reportId');
      if (alertIdx != -1) {
        _alerts[alertIdx] = _alerts[alertIdx].copyWith(
          isActive: newStatus == 'detected',
        );
      }
      _recalculateStats();
      notifyListeners();

      // Persist to SQLite
      DatabaseService.instance.updateReportStatus(reportId, newStatus);
      if (alertIdx != -1) {
        DatabaseService.instance
            .updateAlertActive('HZD-$reportId', newStatus == 'detected');
      }
    }
  }

  void deleteReport(String reportId) {
    _reports.removeWhere((r) => r.id == reportId);
    _alerts.removeWhere((a) => a.id == 'HZD-$reportId');
    _recalculateStats();
    notifyListeners();

    // Persist to SQLite
    DatabaseService.instance.deleteReport(reportId);
    DatabaseService.instance.deleteAlert('HZD-$reportId');
  }

  void clearAllReports() {
    _reports.clear();
    _alerts.clear();
    _recalculateStats();
    notifyListeners();

    // Persist to SQLite
    DatabaseService.instance.clearAllReports();
    DatabaseService.instance.clearAllAlerts();
  }
}
