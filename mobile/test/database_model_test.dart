import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amar_path/core/models.dart';

void main() {
  group('Database & Model Serialization Tests', () {
    test('DamageReport toDatabaseMap and fromMap round-trip', () {
      final now = DateTime.now();
      final report = DamageReport(
        id: 'test-123',
        damageType: 'Pothole Cluster (2 Defects)',
        severity: 'Critical',
        latitude: 23.8103,
        longitude: 90.4125,
        address: 'Mirpur Road, Dhaka',
        timestamp: now,
        status: 'detected',
        confidenceScore: 0.94,
        reportedBy: 'You',
        damageAreaSqM: 0.42,
        notes: 'Deep road cavity',
        imagePath: '/data/user/0/road_captures/img1.jpg',
        crackWidthMm: 12.5,
        estimatedDepthCm: 6.0,
        detections: const [
          DetectedHazard(
            rect: Rect.fromLTWH(0.1, 0.2, 0.3, 0.4),
            confidence: 0.95,
            label: 'Pothole',
          ),
          DetectedHazard(
            rect: Rect.fromLTWH(0.5, 0.6, 0.2, 0.3),
            confidence: 0.88,
            label: 'Pothole',
          ),
        ],
        imageWidth: 640,
        imageHeight: 640,
      );

      final dbMap = report.toDatabaseMap();

      expect(dbMap['id'], 'test-123');
      expect(dbMap['damageType'], 'Pothole Cluster (2 Defects)');
      expect(dbMap['severity'], 'Critical');
      expect(dbMap['detections'], isA<String>()); // Serialized as JSON string in DB

      // Deserialize back from DB map
      final restored = DamageReport.fromMap(dbMap);

      expect(restored.id, 'test-123');
      expect(restored.damageType, 'Pothole Cluster (2 Defects)');
      expect(restored.severity, 'Critical');
      expect(restored.latitude, 23.8103);
      expect(restored.longitude, 90.4125);
      expect(restored.detections.length, 2);
      expect(restored.detections[0].label, 'Pothole');
      expect(restored.detections[0].confidence, 0.95);
      expect(restored.detections[1].confidence, 0.88);
    });

    test('HazardAlert toMap and fromMap round-trip', () {
      final now = DateTime.now();
      final alert = HazardAlert(
        id: 'HZD-001',
        title: 'Critical Pothole',
        severity: 'Critical',
        distanceMeters: 45.0,
        address: 'Airport Road',
        damageType: 'Pothole',
        lastReported: now,
        latitude: 23.85,
        longitude: 90.40,
        isActive: true,
      );

      final map = alert.toMap();
      expect(map['isActive'], 1);

      final restored = HazardAlert.fromMap(map);
      expect(restored.id, 'HZD-001');
      expect(restored.title, 'Critical Pothole');
      expect(restored.isActive, true);
    });
  });
}
