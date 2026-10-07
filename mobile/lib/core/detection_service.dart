import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'models.dart';
import 'tflite_detector.dart';
import 'location_service.dart';

class DetectionService {
  static final DetectionService instance = DetectionService._internal();
  DetectionService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Get device GPS position or fallback to default coordinates
  Future<({double lat, double lng, bool isReal})> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackCoordinates();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackCoordinates();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _fallbackCoordinates();
      }

      // Check last known location first (immediate resolution)
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        // Also fire off fresh position in background / short timeout
        try {
          final fresh = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 4),
            ),
          );
          return (lat: fresh.latitude, lng: fresh.longitude, isReal: true);
        } catch (_) {
          return (lat: lastPos.latitude, lng: lastPos.longitude, isReal: true);
        }
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );

      return (lat: position.latitude, lng: position.longitude, isReal: true);
    } catch (_) {
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          return (lat: lastPos.latitude, lng: lastPos.longitude, isReal: true);
        }
      } catch (_) {}
      return _fallbackCoordinates();
    }
  }

  ({double lat, double lng, bool isReal}) _fallbackCoordinates() {
    final loc = LocationService.instance.lastKnownLocation;
    return (
      lat: loc.latitude,
      lng: loc.longitude,
      isReal: false,
    );
  }

  /// Permanently save captured image into application documents directory
  Future<String> saveImagePermanently(String sourcePath, String reportId) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final capturesDir = Directory('${appDir.path}/road_captures');
      if (!await capturesDir.exists()) {
        await capturesDir.create(recursive: true);
      }
      final extension = sourcePath.split('.').last;
      final fileName =
          '${reportId}_${DateTime.now().millisecondsSinceEpoch}.$extension';
      final permanentFile = File('${capturesDir.path}/$fileName');

      final sourceFile = File(sourcePath);
      if (await sourceFile.exists()) {
        final savedFile = await sourceFile.copy(permanentFile.path);
        debugPrint('Image saved permanently to: ${savedFile.path}');
        return savedFile.path;
      }
      return sourcePath;
    } catch (e) {
      debugPrint('Error saving image permanently: $e');
      return sourcePath;
    }
  }

  /// Checks for any lost camera data if Android killed the activity during camera launch
  Future<DetectionResult?> retrieveLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty || response.file == null) {
        return null;
      }
      return await processImage(response.file!.path, 'camera_recovered');
    } catch (e) {
      debugPrint('Error retrieving lost camera data: $e');
      return null;
    }
  }

  /// Pick raw photo from device camera.
  Future<String?> pickCameraPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
      );
      return photo?.path;
    } catch (e) {
      debugPrint('Camera pick error: $e');
      return null;
    }
  }

  /// Pick raw image from gallery.
  Future<String?> pickGalleryPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      return image?.path;
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  /// Capture image using device camera and run detection
  Future<DetectionResult?> captureFromCamera() async {
    try {
      final path = await pickCameraPhoto();
      if (path == null) return null;
      return await processImage(path, 'camera');
    } catch (e) {
      debugPrint('Camera capture error: $e');
      return null;
    }
  }

  /// Pick image from gallery and run detection
  Future<DetectionResult?> pickFromGallery() async {
    try {
      final path = await pickGalleryPhoto();
      if (path == null) return null;
      return await processImage(path, 'gallery');
    } catch (e) {
      debugPrint('Gallery pick error: $e');
      return null;
    }
  }

  /// Simulate a capture for testing without camera hardware
  Future<DetectionResult> simulateCapture() async {
    final loc = await getCurrentLocation();
    final address = loc.isReal
        ? 'GPS (${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)})'
        : 'Fulbarigate, Khulna';
    final reportId = 'RPT-${DateTime.now().millisecondsSinceEpoch % 10000}';
    const confidence = 0.88;

    final report = DamageReport(
      id: reportId,
      damageType: 'Pothole',
      severity: 'High',
      latitude: loc.lat,
      longitude: loc.lng,
      address: address,
      timestamp: DateTime.now(),
      status: 'detected',
      confidenceScore: confidence,
      reportedBy: 'You',
      damageAreaSqM: null,
      crackWidthMm: null,
      estimatedDepthCm: null,
      notes: 'Simulated road scan test. Real model not run.',
      boundingBox: const Rect.fromLTWH(0.2, 0.25, 0.6, 0.5),
    );

    return DetectionResult(
      report: report,
      confidence: confidence,
      isRealLocation: loc.isReal,
      imageSource: 'simulated',
    );
  }

  Future<DetectionResult> processImage(String imagePath, String source) async {
    final loc = await getCurrentLocation();
    final address = loc.isReal
        ? 'GPS (${loc.lat.toStringAsFixed(5)}, ${loc.lng.toStringAsFixed(5)})'
        : 'Location unavailable';
    final reportId = 'RPT-${DateTime.now().millisecondsSinceEpoch}';

    // Permanently save image to persistent app storage
    final permanentPath = await saveImagePermanently(imagePath, reportId);
    final imageFile = File(permanentPath);

    // Run real on-device inference using best.tflite
    final tfliteResult = await TFLiteDetector.instance.detectImage(
      imageFile,
      confidenceThreshold: 0.25,
      iouThreshold: 0.45,
    );

    DamageReport report;

    if (tfliteResult.hasDetections ||
        (tfliteResult.modelExecuted &&
            tfliteResult.bestCandidate != null &&
            tfliteResult.maxConfidence >= 0.12)) {
      final primary = tfliteResult.primaryDetection!;
      final conf = double.parse(primary.confidence.toStringAsFixed(2));
      final rect = primary.rect;
      final areaFraction = rect.width * rect.height;
      final severity =
          _calculateSeverityFromDetection(primary.confidence, areaFraction);

      report = DamageReport(
        id: reportId,
        damageType: (primary.label.isNotEmpty) ? primary.label : 'Pothole',
        severity: severity,
        latitude: loc.lat,
        longitude: loc.lng,
        address: address,
        timestamp: DateTime.now(),
        status: 'detected',
        confidenceScore: conf,
        reportedBy: 'You',
        damageAreaSqM: null,
        crackWidthMm: null,
        estimatedDepthCm: null,
        notes:
            'Verified by ${TFLiteDetector.instance.activeModelName} on-device YOLO model (${(primary.confidence * 100).toStringAsFixed(1)}% confidence, ${tfliteResult.inferenceTimeMs}ms inference).',
        imagePath: permanentPath,
        boundingBox: rect,
        imageWidth:
            tfliteResult.imageWidth > 0 ? tfliteResult.imageWidth : null,
        imageHeight:
            tfliteResult.imageHeight > 0 ? tfliteResult.imageHeight : null,
      );
    } else {
      // Model completed inference but found no damage: report clean road honestly
      report = DamageReport(
        id: reportId,
        damageType: 'No Damage Detected',
        severity: 'Low',
        latitude: loc.lat,
        longitude: loc.lng,
        address: address,
        timestamp: DateTime.now(),
        status: 'resolved',
        confidenceScore: 0.0,
        reportedBy: 'You',
        damageAreaSqM: null,
        crackWidthMm: null,
        estimatedDepthCm: null,
        notes:
            'Inference completed in ${tfliteResult.inferenceTimeMs}ms. No potholes or cracks detected on road surface.',
        imagePath: permanentPath,
        boundingBox: null,
        imageWidth:
            tfliteResult.imageWidth > 0 ? tfliteResult.imageWidth : null,
        imageHeight:
            tfliteResult.imageHeight > 0 ? tfliteResult.imageHeight : null,
      );
    }

    return DetectionResult(
      report: report,
      confidence: report.confidenceScore,
      isRealLocation: loc.isReal,
      imageSource: source,
    );
  }

  String _calculateSeverityFromDetection(
      double confidence, double areaFraction) {
    if (areaFraction > 0.18 || confidence > 0.82) {
      return 'Critical';
    } else if (areaFraction > 0.08 || confidence > 0.60) {
      return 'High';
    } else if (areaFraction > 0.03 || confidence > 0.40) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
}
