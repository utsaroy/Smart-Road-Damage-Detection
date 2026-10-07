import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'report_repository.dart';

/// Single detection bounding box returned by YOLO model
class DetectionBox {
  final Rect rect; // Normalized coordinates 0.0 .. 1.0 (left, top, width, height)
  final double confidence; // Confidence score 0.0 .. 1.0
  final String label; // Detected class name ('Pothole', 'Longitudinal Crack', etc.)

  const DetectionBox({
    required this.rect,
    required this.confidence,
    this.label = 'Pothole',
  });

  @override
  String toString() =>
      'DetectionBox(label: $label, conf: ${(confidence * 100).toStringAsFixed(1)}%, rect: $rect)';
}

/// Result envelope containing detections and runtime metrics
class TFLiteDetectionResult {
  final List<DetectionBox> detections;
  final DetectionBox? bestCandidate;
  final double maxConfidence;
  final int inferenceTimeMs;
  final bool modelExecuted;
  final int imageWidth;
  final int imageHeight;
  final String? errorMessage;

  const TFLiteDetectionResult({
    required this.detections,
    this.bestCandidate,
    required this.maxConfidence,
    required this.inferenceTimeMs,
    required this.modelExecuted,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.errorMessage,
  });

  bool get hasDetections => detections.isNotEmpty;
  DetectionBox? get primaryDetection =>
      detections.isNotEmpty ? detections.first : bestCandidate;
}

/// Metadata describing the currently active TFLite model architecture
class ModelMetadata {
  final String name;
  final String path;
  final bool isCustom;
  final int inputWidth;
  final int inputHeight;
  final bool isChannelsFirst;
  final int numAnchors;
  final int numAttributes;
  final int numClasses;
  final List<String> classNames;
  final int fileSizeBytes;

  const ModelMetadata({
    required this.name,
    required this.path,
    required this.isCustom,
    required this.inputWidth,
    required this.inputHeight,
    required this.isChannelsFirst,
    required this.numAnchors,
    required this.numAttributes,
    required this.numClasses,
    required this.classNames,
    this.fileSizeBytes = 0,
  });

  String get resolutionStr => '$inputWidth×$inputHeight';
  String get tensorLayoutStr =>
      isChannelsFirst ? 'NCHW (1, 3, H, W)' : 'NHWC (1, H, W, 3)';
  String get outputShapeStr => '[1, $numAttributes, $numAnchors]';
  String get fileSizeStr {
    if (fileSizeBytes <= 0) return 'Bundled Asset';
    final mb = fileSizeBytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }
}

/// Response returned when importing/browsing a custom model
class ModelLoadResult {
  final bool success;
  final String? errorMessage;
  final ModelMetadata? modelInfo;

  const ModelLoadResult({
    required this.success,
    this.errorMessage,
    this.modelInfo,
  });
}

/// Dynamic service managing YOLO on-device model lifecycle,
/// supporting both bundled best.tflite and user-browsed custom models.
class TFLiteDetector extends ChangeNotifier {
  static final TFLiteDetector instance = TFLiteDetector._internal();
  TFLiteDetector._internal();

  static const String modelAssetPath = 'assets/models/best.tflite';

  Interpreter? _interpreter;
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _initError;

  String _activeModelPath = modelAssetPath;
  String _activeModelName = 'best.tflite';
  bool _isCustomModel = false;

  // Dynamic input tensor properties
  int _inputWidth = 640;
  int _inputHeight = 640;
  bool _isChannelsFirst = true;

  // Dynamic output tensor properties
  int _numAnchors = 8400;
  int _numAttributes = 5;
  int _numClasses = 1;
  bool _isTransposed = false;
  int _outputElementCount = 42000;
  List<String> _classNames = const ['Pothole'];
  int _fileSizeBytes = 0;

  bool get isLoaded => _isInitialized && _interpreter != null;
  String? get initError => _initError;
  String get activeModelName => _activeModelName;
  bool get isCustomModel => _isCustomModel;

  ModelMetadata get currentModelInfo => ModelMetadata(
        name: _activeModelName,
        path: _activeModelPath,
        isCustom: _isCustomModel,
        inputWidth: _inputWidth,
        inputHeight: _inputHeight,
        isChannelsFirst: _isChannelsFirst,
        numAnchors: _numAnchors,
        numAttributes: _numAttributes,
        numClasses: _numClasses,
        classNames: _classNames,
        fileSizeBytes: _fileSizeBytes,
      );

  /// Initialize and load model into memory
  Future<bool> initialize() async {
    if (_isInitialized && _interpreter != null) return true;
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _isInitialized;
    }

    _isInitializing = true;
    _initError = null;

    try {
      final options = InterpreterOptions()..threads = 4;

      if (_isCustomModel && File(_activeModelPath).existsSync()) {
        debugPrint(
            'TFLiteDetector: Loading custom model from $_activeModelPath...');
        final file = File(_activeModelPath);
        _interpreter = Interpreter.fromFile(file, options: options);
        _fileSizeBytes = file.lengthSync();
      } else {
        debugPrint(
            'TFLiteDetector: Initializing bundled model from $modelAssetPath...');
        _interpreter =
            await Interpreter.fromAsset(modelAssetPath, options: options);
        _activeModelPath = modelAssetPath;
        _activeModelName = 'best.tflite';
        _isCustomModel = false;
        _fileSizeBytes = 0;
      }

      _configureTensorsFromInterpreter();

      _isInitialized = true;
      _isInitializing = false;
      notifyListeners();
      return true;
    } catch (e, stack) {
      _initError = e.toString();
      _isInitialized = false;
      _isInitializing = false;
      debugPrint('TFLiteDetector: Initialization error: $e\n$stack');
      return false;
    }
  }

  /// Inspects tensor shapes from the loaded interpreter and configures input/output formats dynamically
  void _configureTensorsFromInterpreter() {
    if (_interpreter == null) return;

    final inputTensor = _interpreter!.getInputTensor(0);
    final outputTensor = _interpreter!.getOutputTensor(0);

    final inputShape = inputTensor.shape;
    final outputShape = outputTensor.shape;

    debugPrint(
        'TFLiteDetector: Tensor configuration - Inputs: $inputShape, Outputs: $outputShape');

    // 1. Parse Input Shape
    if (inputShape.length == 4) {
      if (inputShape[1] == 3) {
        // [1, 3, H, W] - Channels first
        _isChannelsFirst = true;
        _inputHeight = inputShape[2];
        _inputWidth = inputShape[3];
      } else if (inputShape[3] == 3) {
        // [1, H, W, 3] - Channels last
        _isChannelsFirst = false;
        _inputHeight = inputShape[1];
        _inputWidth = inputShape[2];
      } else {
        _isChannelsFirst = true;
        _inputHeight = 640;
        _inputWidth = 640;
      }
    } else {
      _isChannelsFirst = true;
      _inputHeight = 640;
      _inputWidth = 640;
    }

    // 2. Parse Output Shape
    _outputElementCount = outputShape.reduce((a, b) => a * b);

    if (outputShape.length == 3) {
      if (outputShape[1] < outputShape[2]) {
        // Standard YOLO: [1, attributes, anchors] (e.g. [1, 5, 8400] or [1, 8, 8400])
        _isTransposed = false;
        _numAttributes = outputShape[1];
        _numAnchors = outputShape[2];
      } else {
        // Transposed YOLO: [1, anchors, attributes] (e.g. [1, 8400, 5])
        _isTransposed = true;
        _numAnchors = outputShape[1];
        _numAttributes = outputShape[2];
      }
    } else {
      _isTransposed = false;
      _numAttributes = 5;
      _numAnchors = 8400;
    }

    // Classes = Attributes - 4 (cx, cy, w, h)
    _numClasses = math.max(1, _numAttributes - 4);

    // Dynamic Class Label Mapping
    if (_numClasses == 1) {
      _classNames = const ['Pothole'];
    } else if (_numClasses == 4) {
      _classNames = const [
        'Pothole',
        'Longitudinal Crack',
        'Transverse Crack',
        'Alligator Crack',
      ];
    } else {
      const defaultLabels = [
        'Pothole',
        'Longitudinal Crack',
        'Transverse Crack',
        'Alligator Crack',
        'Manhole Defect',
        'Rutting',
        'Ravelling',
        'Depression',
      ];
      _classNames = List.generate(
        _numClasses,
        (i) => i < defaultLabels.length
            ? defaultLabels[i]
            : 'Damage Class ${i + 1}',
      );
    }
  }

  /// Browses and imports a custom user .tflite model from the filesystem
  Future<ModelLoadResult> loadCustomModel(String sourcePath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!sourceFile.existsSync()) {
        return ModelLoadResult(
          success: false,
          errorMessage: 'Selected file does not exist: $sourcePath',
        );
      }

      // Copy to persistent application storage
      final appDir = await getApplicationDocumentsDirectory();
      final modelsDir = Directory(p.join(appDir.path, 'custom_models'));
      if (!modelsDir.existsSync()) {
        await modelsDir.create(recursive: true);
      }

      final fileName = p.basename(sourcePath);
      final destPath = p.join(modelsDir.path, fileName);
      await sourceFile.copy(destPath);
      final destFile = File(destPath);

      // Verify model can be loaded with LiteRT interpreter
      final options = InterpreterOptions()..threads = 4;
      final testInterpreter = Interpreter.fromFile(
        destFile,
        options: options,
      );

      final inputs = testInterpreter.getInputTensors();
      final outputs = testInterpreter.getOutputTensors();

      if (inputs.isEmpty || outputs.isEmpty) {
        testInterpreter.close();
        return const ModelLoadResult(
          success: false,
          errorMessage: 'Invalid TFLite model: Missing input or output tensors',
        );
      }

      // Close previous interpreter safely
      _interpreter?.close();
      _interpreter = testInterpreter;

      _activeModelPath = destPath;
      _activeModelName = fileName;
      _isCustomModel = true;
      _fileSizeBytes = destFile.lengthSync();

      _configureTensorsFromInterpreter();

      _isInitialized = true;
      _initError = null;

      ReportRepository.instance.setAiModel('$_activeModelName (Custom YOLO)');
      notifyListeners();

      return ModelLoadResult(
        success: true,
        modelInfo: currentModelInfo,
      );
    } catch (e) {
      debugPrint('Error loading custom model: $e');
      return ModelLoadResult(
        success: false,
        errorMessage: 'Failed to initialize model: $e',
      );
    }
  }

  /// Reset active model back to bundled assets/models/best.tflite
  Future<void> resetToDefaultModel() async {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;

    _activeModelPath = modelAssetPath;
    _activeModelName = 'best.tflite';
    _isCustomModel = false;
    _fileSizeBytes = 0;

    ReportRepository.instance.setAiModel('best.tflite (YOLOv8 On-Device)');
    await initialize();
    notifyListeners();
  }

  /// Run damage detection inference on an image file
  Future<TFLiteDetectionResult> detectImage(
    File imageFile, {
    double confidenceThreshold = 0.20,
    double iouThreshold = 0.45,
  }) async {
    final stopwatch = Stopwatch()..start();

    if (!_isInitialized) {
      final success = await initialize();
      if (!success || _interpreter == null) {
        stopwatch.stop();
        return TFLiteDetectionResult(
          detections: [],
          maxConfidence: 0.0,
          inferenceTimeMs: stopwatch.elapsedMilliseconds,
          modelExecuted: false,
          errorMessage: _initError ?? 'Model interpreter not loaded',
        );
      }
    }

    try {
      // 1. Offload image reading, EXIF rotation & resizing to isolate
      final preprocessed = await compute(
        _preprocessImageWorker,
        _PreprocessParams(
          imagePath: imageFile.path,
          targetWidth: _inputWidth,
          targetHeight: _inputHeight,
          isChannelsFirst: _isChannelsFirst,
        ),
      );

      if (preprocessed == null) {
        stopwatch.stop();
        return TFLiteDetectionResult(
          detections: [],
          maxConfidence: 0.0,
          inferenceTimeMs: stopwatch.elapsedMilliseconds,
          modelExecuted: false,
          errorMessage: 'Failed to decode or preprocess image',
        );
      }

      final Float32List inputBuffer = preprocessed.inputBuffer;
      final int origWidth = preprocessed.origWidth;
      final int origHeight = preprocessed.origHeight;

      // 2. Output buffer allocated dynamically based on model output tensor size
      final Float32List outputBuffer = Float32List(_outputElementCount);

      // 3. Multi-threaded LiteRT inference
      _interpreter!.run(inputBuffer.buffer, outputBuffer.buffer);
      stopwatch.stop();

      // 4. Parse detection candidates
      final List<DetectionBox> candidateBoxes = [];
      double highestConfidenceSeen = 0.0;
      DetectionBox? bestCandidateBelowThreshold;

      for (int i = 0; i < _numAnchors; i++) {
        double cx;
        double cy;
        double w;
        double h;
        double maxClassScore = 0.0;
        int bestClassIdx = 0;

        if (!_isTransposed) {
          cx = outputBuffer[0 * _numAnchors + i];
          cy = outputBuffer[1 * _numAnchors + i];
          w = outputBuffer[2 * _numAnchors + i];
          h = outputBuffer[3 * _numAnchors + i];

          for (int c = 0; c < _numClasses; c++) {
            final double s = outputBuffer[(4 + c) * _numAnchors + i];
            if (s > maxClassScore) {
              maxClassScore = s;
              bestClassIdx = c;
            }
          }
        } else {
          final int offset = i * _numAttributes;
          cx = outputBuffer[offset + 0];
          cy = outputBuffer[offset + 1];
          w = outputBuffer[offset + 2];
          h = outputBuffer[offset + 3];

          for (int c = 0; c < _numClasses; c++) {
            final double s = outputBuffer[offset + 4 + c];
            if (s > maxClassScore) {
              maxClassScore = s;
              bestClassIdx = c;
            }
          }
        }

        if (maxClassScore > highestConfidenceSeen) {
          highestConfidenceSeen = maxClassScore;
        }

        if (cx.isNaN || cy.isNaN || w.isNaN || h.isNaN) continue;

        // Symmetric bounding box calculation (normalized [0, 1])
        final double x1 = (cx - w / 2.0).clamp(0.0, 1.0);
        final double y1 = (cy - h / 2.0).clamp(0.0, 1.0);
        final double x2 = (cx + w / 2.0).clamp(0.0, 1.0);
        final double y2 = (cy + h / 2.0).clamp(0.0, 1.0);
        final double boxWidth = math.max(0.0, x2 - x1);
        final double boxHeight = math.max(0.0, y2 - y1);

        if (boxWidth <= 0.005 || boxHeight <= 0.005) continue;

        final String label = bestClassIdx < _classNames.length
            ? _classNames[bestClassIdx]
            : 'Pothole';

        final box = DetectionBox(
          rect: Rect.fromLTWH(x1, y1, boxWidth, boxHeight),
          confidence: maxClassScore,
          label: label,
        );

        if (maxClassScore >= confidenceThreshold) {
          candidateBoxes.add(box);
        } else if (bestCandidateBelowThreshold == null ||
            maxClassScore > bestCandidateBelowThreshold.confidence) {
          bestCandidateBelowThreshold = box;
        }
      }

      // 5. Sort by confidence descending
      candidateBoxes.sort((a, b) => b.confidence.compareTo(a.confidence));

      // 6. Non-Maximum Suppression (NMS)
      final List<DetectionBox> nmsResults =
          _applyNms(candidateBoxes, iouThreshold);

      debugPrint(
        'TFLiteDetector [$_activeModelName]: Inference took ${stopwatch.elapsedMilliseconds}ms. '
        'Max conf: ${(highestConfidenceSeen * 100).toStringAsFixed(1)}%. '
        'Boxes detected: ${nmsResults.length}',
      );

      return TFLiteDetectionResult(
        detections: nmsResults,
        bestCandidate: bestCandidateBelowThreshold,
        maxConfidence: highestConfidenceSeen,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
        modelExecuted: true,
        imageWidth: origWidth,
        imageHeight: origHeight,
      );
    } catch (e, stack) {
      stopwatch.stop();
      debugPrint('TFLiteDetector: Inference error: $e\n$stack');
      return TFLiteDetectionResult(
        detections: [],
        maxConfidence: 0.0,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
        modelExecuted: false,
        errorMessage: e.toString(),
      );
    }
  }

  List<DetectionBox> _applyNms(List<DetectionBox> boxes, double iouThresh) {
    final List<DetectionBox> selected = [];

    for (final box in boxes) {
      bool keep = true;
      for (final chosen in selected) {
        if (_computeIoU(box.rect, chosen.rect) > iouThresh) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(box);
      }
    }

    return selected;
  }

  double _computeIoU(Rect a, Rect b) {
    final double x1 = math.max(a.left, b.left);
    final double y1 = math.max(a.top, b.top);
    final double x2 = math.min(a.right, b.right);
    final double y2 = math.min(a.bottom, b.bottom);

    final double intersectionWidth = math.max(0.0, x2 - x1);
    final double intersectionHeight = math.max(0.0, y2 - y1);
    final double intersectionArea = intersectionWidth * intersectionHeight;

    final double areaA = a.width * a.height;
    final double areaB = b.width * b.height;
    final double unionArea = areaA + areaB - intersectionArea;

    if (unionArea <= 0.0) return 0.0;
    return intersectionArea / unionArea;
  }

  @override
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
    super.dispose();
  }
}

class _PreprocessParams {
  final String imagePath;
  final int targetWidth;
  final int targetHeight;
  final bool isChannelsFirst;

  const _PreprocessParams({
    required this.imagePath,
    required this.targetWidth,
    required this.targetHeight,
    required this.isChannelsFirst,
  });
}

class _PreprocessedData {
  final Float32List inputBuffer;
  final int origWidth;
  final int origHeight;

  _PreprocessedData({
    required this.inputBuffer,
    required this.origWidth,
    required this.origHeight,
  });
}

_PreprocessedData? _preprocessImageWorker(_PreprocessParams params) {
  try {
    final file = File(params.imagePath);
    if (!file.existsSync()) return null;
    final Uint8List rawBytes = file.readAsBytesSync();
    final img.Image? decoded = img.decodeImage(rawBytes);
    if (decoded == null) return null;

    final img.Image oriented = img.bakeOrientation(decoded);
    final int origWidth = oriented.width;
    final int origHeight = oriented.height;

    final int targetWidth = params.targetWidth;
    final int targetHeight = params.targetHeight;
    final bool isChannelsFirst = params.isChannelsFirst;

    final img.Image resized = img.copyResize(
      oriented,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    final int totalPixels = targetWidth * targetHeight;
    final Float32List inputBuffer = Float32List(1 * 3 * totalPixels);

    if (isChannelsFirst) {
      final int channelSize = totalPixels;
      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final pixel = resized.getPixel(x, y);
          final int pixelIndex = y * targetWidth + x;
          inputBuffer[pixelIndex] = pixel.rNormalized.toDouble();
          inputBuffer[channelSize + pixelIndex] = pixel.gNormalized.toDouble();
          inputBuffer[channelSize * 2 + pixelIndex] =
              pixel.bNormalized.toDouble();
        }
      }
    } else {
      int idx = 0;
      for (int y = 0; y < targetHeight; y++) {
        for (int x = 0; x < targetWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputBuffer[idx++] = pixel.rNormalized.toDouble();
          inputBuffer[idx++] = pixel.gNormalized.toDouble();
          inputBuffer[idx++] = pixel.bNormalized.toDouble();
        }
      }
    }

    return _PreprocessedData(
      inputBuffer: inputBuffer,
      origWidth: origWidth,
      origHeight: origHeight,
    );
  } catch (e) {
    debugPrint('_preprocessImageWorker isolate error: $e');
    return null;
  }
}
