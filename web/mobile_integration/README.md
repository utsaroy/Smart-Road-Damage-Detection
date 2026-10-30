# Android App (Amar Path) Integration with Website Database

This guide explains how your Flutter Android app (`amar_path`) connects automatically to the central PHP Website Database so that every detection made by any user using the app is stored in the website database in real-time.

---

## 1. Files & API Endpoints

- **Live Server Base URL**: `http://192.168.0.107:8000` (or `http://localhost:8000` on emulator `http://10.0.2.2:8000`)
- **Real-Time Ingestion Endpoint**: `POST /api/report_hazard.php`
- **Batch / Offline Sync Endpoint**: `POST /api/sync_reports.php`
- **Nearby Hazard Alerts Endpoint**: `GET /api/hazard_alerts.php?latitude=...&longitude=...`
- **Direct Phone SQLite Importer**: `POST /api/import_app_db.php`

---

## 2. Drop-in Dart Service File

Copy `ReportSyncService.dart` into your Flutter app project under:
`lib/core/report_sync_service.dart`

---

## 3. Hook into App's Local Storage (`report_repository.dart`)

Inside `lib/core/report_repository.dart`, where `insertReport(DamageReport report)` is called:

```dart
import 'package:amar_path/core/report_sync_service.dart';

Future<void> insertReport(DamageReport report) async {
  // 1. Save to local SQLite (existing app code)
  await databaseService.insert('damage_reports', report.toMap());

  // 2. Automatically sync to central website database in background
  ReportSyncService.uploadDamageReport(
    id: report.id,
    damageType: report.damageType,
    severity: report.severity,
    latitude: report.latitude,
    longitude: report.longitude,
    address: report.address,
    timestamp: report.timestamp,
    status: report.status,
    confidenceScore: report.confidenceScore,
    reportedBy: report.reportedBy,
    damageAreaSqM: report.damageAreaSqM,
    notes: report.notes,
    imagePath: report.imagePath,
    crackWidthMm: report.crackWidthMm,
    estimatedDepthCm: report.estimatedDepthCm,
    detections: report.detections,
    bboxLeft: report.bbox_left,
    bboxTop: report.bbox_top,
    bboxRight: report.bbox_right,
    bboxBottom: report.bbox_bottom,
    imageWidth: report.imageWidth,
    imageHeight: report.imageHeight,
  );
}
```

---

## 4. Multi-User Support

Each device running the app automatically identifies itself using its own unique device name or user profile from `profile_screen.dart` / `reportedBy`. 
All users' data appears live on the Road Authority Dashboard table and GIS map!

---

## 5. Offline & Batch Sync

If a user captures potholes while having no internet connection:
Call `ReportSyncService.batchSyncReports(pendingReportsList)` as soon as internet connectivity is restored. All reports will be ingested instantly.
