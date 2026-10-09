import 'package:flutter/material.dart';

/// Represents a single road damage hazard detected by the YOLO model.
class DetectedHazard {
  final Rect rect; // Normalized coordinates 0.0 .. 1.0 (left, top, width, height)
  final double confidence; // Confidence score 0.0 .. 1.0
  final String label; // Detected class name ('Pothole', 'Longitudinal Crack', etc.)

  const DetectedHazard({
    required this.rect,
    required this.confidence,
    this.label = 'Pothole',
  });

  double get areaFraction => rect.width * rect.height;

  Map<String, dynamic> toMap() => {
        'left': rect.left,
        'top': rect.top,
        'width': rect.width,
        'height': rect.height,
        'confidence': confidence,
        'label': label,
      };

  factory DetectedHazard.fromMap(Map<String, dynamic> map) => DetectedHazard(
        rect: Rect.fromLTWH(
          (map['left'] as num).toDouble(),
          (map['top'] as num).toDouble(),
          (map['width'] as num).toDouble(),
          (map['height'] as num).toDouble(),
        ),
        confidence: (map['confidence'] as num).toDouble(),
        label: map['label'] as String? ?? 'Pothole',
      );

  @override
  String toString() =>
      'DetectedHazard($label, ${(confidence * 100).toStringAsFixed(1)}%, $rect)';
}

/// Data models for the Smart Road System app.
class DamageReport {
  final String id;
  final String damageType;
  final String severity; // 'Critical', 'High', 'Medium', 'Low'
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String status; // 'pending', 'processing', 'detected', 'resolved'
  final double confidenceScore;
  final String reportedBy;
  final double? damageAreaSqM;
  final String? notes;
  final String? imagePath; // Local file path from camera/gallery
  final double? crackWidthMm;
  final double? estimatedDepthCm;
  final List<DetectedHazard> detections;
  final Rect? _legacyBoundingBox;
  final int? imageWidth;
  final int? imageHeight;

  const DamageReport({
    required this.id,
    required this.damageType,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.status,
    required this.confidenceScore,
    required this.reportedBy,
    this.damageAreaSqM,
    this.notes,
    this.imagePath,
    this.crackWidthMm,
    this.estimatedDepthCm,
    this.detections = const [],
    Rect? boundingBox,
    this.imageWidth,
    this.imageHeight,
  }) : _legacyBoundingBox = boundingBox;

  /// Primary bounding box for backward compatibility with single-box views
  Rect? get boundingBox =>
      detections.isNotEmpty ? detections.first.rect : _legacyBoundingBox;

  int get defectCount => detections.length;
  bool get hasMultipleDefects => detections.length > 1;
  double get totalDamageAreaFraction =>
      detections.fold(0.0, (sum, d) => sum + d.areaFraction);

  DamageReport copyWith({
    String? id,
    String? damageType,
    String? severity,
    double? latitude,
    double? longitude,
    String? address,
    DateTime? timestamp,
    String? status,
    double? confidenceScore,
    String? reportedBy,
    double? damageAreaSqM,
    String? notes,
    String? imagePath,
    double? crackWidthMm,
    double? estimatedDepthCm,
    List<DetectedHazard>? detections,
    Rect? boundingBox,
    int? imageWidth,
    int? imageHeight,
  }) {
    return DamageReport(
      id: id ?? this.id,
      damageType: damageType ?? this.damageType,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      reportedBy: reportedBy ?? this.reportedBy,
      damageAreaSqM: damageAreaSqM ?? this.damageAreaSqM,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      crackWidthMm: crackWidthMm ?? this.crackWidthMm,
      estimatedDepthCm: estimatedDepthCm ?? this.estimatedDepthCm,
      detections: detections ?? this.detections,
      boundingBox: boundingBox ?? _legacyBoundingBox,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'damageType': damageType,
      'severity': severity,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'confidenceScore': confidenceScore,
      'reportedBy': reportedBy,
      'damageAreaSqM': damageAreaSqM,
      'notes': notes,
      'imagePath': imagePath,
      'crackWidthMm': crackWidthMm,
      'estimatedDepthCm': estimatedDepthCm,
      'detections': detections.map((d) => d.toMap()).toList(),
      'bbox_left': boundingBox?.left,
      'bbox_top': boundingBox?.top,
      'bbox_right': boundingBox?.right,
      'bbox_bottom': boundingBox?.bottom,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
    };
  }

  factory DamageReport.fromMap(Map<String, dynamic> map) {
    Rect? box;
    if (map['bbox_left'] != null &&
        map['bbox_top'] != null &&
        map['bbox_right'] != null &&
        map['bbox_bottom'] != null) {
      box = Rect.fromLTRB(
        (map['bbox_left'] as num).toDouble(),
        (map['bbox_top'] as num).toDouble(),
        (map['bbox_right'] as num).toDouble(),
        (map['bbox_bottom'] as num).toDouble(),
      );
    }

    List<DetectedHazard> detectionsList = [];
    if (map['detections'] != null && map['detections'] is List) {
      detectionsList = (map['detections'] as List)
          .map((item) =>
              DetectedHazard.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } else if (box != null) {
      detectionsList = [
        DetectedHazard(
          rect: box,
          confidence: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
          label: map['damageType'] as String? ?? 'Pothole',
        ),
      ];
    }

    return DamageReport(
      id: map['id'] as String,
      damageType: map['damageType'] as String,
      severity: map['severity'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      address: map['address'] as String? ?? 'Unknown Location',
      timestamp:
          DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: map['status'] as String? ?? 'detected',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      reportedBy: map['reportedBy'] as String? ?? 'You',
      damageAreaSqM: (map['damageAreaSqM'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      imagePath: map['imagePath'] as String?,
      crackWidthMm: (map['crackWidthMm'] as num?)?.toDouble(),
      estimatedDepthCm: (map['estimatedDepthCm'] as num?)?.toDouble(),
      detections: detectionsList,
      boundingBox: box,
      imageWidth: map['imageWidth'] as int?,
      imageHeight: map['imageHeight'] as int?,
    );
  }

  IconData get statusIcon {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'processing':
        return Icons.sync;
      case 'detected':
        return Icons.check_circle_outline;
      case 'resolved':
        return Icons.task_alt;
      default:
        return Icons.help_outline;
    }
  }

  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.grey;
      case 'processing':
        return Colors.blue;
      case 'detected':
        return Colors.orange;
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

class HazardAlert {
  final String id;
  final String title;
  final String severity;
  final double distanceMeters;
  final String address;
  final String damageType;
  final DateTime lastReported;
  final double latitude;
  final double longitude;
  final bool isActive;

  const HazardAlert({
    required this.id,
    required this.title,
    required this.severity,
    required this.distanceMeters,
    required this.address,
    required this.damageType,
    required this.lastReported,
    this.latitude = 23.8103,
    this.longitude = 90.4125,
    this.isActive = true,
  });

  HazardAlert copyWith({
    String? id,
    String? title,
    String? severity,
    double? distanceMeters,
    String? address,
    String? damageType,
    DateTime? lastReported,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) {
    return HazardAlert(
      id: id ?? this.id,
      title: title ?? this.title,
      severity: severity ?? this.severity,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      address: address ?? this.address,
      damageType: damageType ?? this.damageType,
      lastReported: lastReported ?? this.lastReported,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'severity': severity,
      'distanceMeters': distanceMeters,
      'address': address,
      'damageType': damageType,
      'lastReported': lastReported.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory HazardAlert.fromMap(Map<String, dynamic> map) {
    return HazardAlert(
      id: map['id'] as String,
      title: map['title'] as String,
      severity: map['severity'] as String,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      address: map['address'] as String? ?? '',
      damageType: map['damageType'] as String? ?? 'Pothole',
      lastReported:
          DateTime.tryParse(map['lastReported'] as String? ?? '') ??
          DateTime.now(),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 23.8103,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 90.4125,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }
}

class UserStats {
  final int totalCaptures;
  final int pendingProcessing;
  final int detectedDamages;
  final int resolvedIssues;
  final int alertsTriggered;
  final double kmCovered;

  const UserStats({
    required this.totalCaptures,
    required this.pendingProcessing,
    required this.detectedDamages,
    required this.resolvedIssues,
    required this.alertsTriggered,
    required this.kmCovered,
  });

  UserStats copyWith({
    int? totalCaptures,
    int? pendingProcessing,
    int? detectedDamages,
    int? resolvedIssues,
    int? alertsTriggered,
    double? kmCovered,
  }) {
    return UserStats(
      totalCaptures: totalCaptures ?? this.totalCaptures,
      pendingProcessing: pendingProcessing ?? this.pendingProcessing,
      detectedDamages: detectedDamages ?? this.detectedDamages,
      resolvedIssues: resolvedIssues ?? this.resolvedIssues,
      alertsTriggered: alertsTriggered ?? this.alertsTriggered,
      kmCovered: kmCovered ?? this.kmCovered,
    );
  }
}

/// Unified item for representing detected road damage or hazard alerts on the map and radar.
class MapHazardItem {
  final String id;
  final String title;
  final String damageType;
  final String severity;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final double confidence;
  final String? imagePath;
  final bool isUserCapture;
  final DamageReport? sourceReport;
  final double distanceMeters;

  const MapHazardItem({
    required this.id,
    required this.title,
    required this.damageType,
    required this.severity,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.confidence,
    this.imagePath,
    this.isUserCapture = false,
    this.sourceReport,
    this.distanceMeters = 0.0,
  });

  MapHazardItem copyWithDistance(double dist) {
    return MapHazardItem(
      id: id,
      title: title,
      damageType: damageType,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      address: address,
      timestamp: timestamp,
      confidence: confidence,
      imagePath: imagePath,
      isUserCapture: isUserCapture,
      sourceReport: sourceReport,
      distanceMeters: dist,
    );
  }
}

/// Result returned from Camera capture / simulated AI detection
class DetectionResult {
  final DamageReport report;
  final double confidence;
  final bool isRealLocation;
  final String? imageSource;

  DetectionResult({
    required this.report,
    double? confidence,
    this.isRealLocation = true,
    this.imageSource,
  }) : confidence = confidence ?? report.confidenceScore;
}
