import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../core/report_repository.dart';
import '../core/detection_service.dart';

/// Full-screen in-app camera capture and AI scanner HUD.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isTorchOn = false;
  String? _initError;
  String _statusMessage = 'Processing Frame...';
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _initError = 'No camera found on this device.';
          });
        }
        return;
      }

      // Default to back camera
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Could not access camera: $e';
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    final prevController = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await prevController?.dispose();

    if (!mounted) return;

    setState(() {
      _controller = controller;
      _isInitializing = true;
      _initError = null;
    });

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Camera initialization failed: $e';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty && _controller == null) {
        _setupController(_cameras[_selectedCameraIndex]);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      setState(() => _isTorchOn = !_isTorchOn);
      HapticFeedback.selectionClick();
      return;
    }

    try {
      final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await controller.setFlashMode(newMode);
      if (mounted) {
        setState(() => _isTorchOn = !_isTorchOn);
        HapticFeedback.selectionClick();
      }
    } catch (_) {
      setState(() => _isTorchOn = !_isTorchOn);
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Single camera detected on device.'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = nextIndex;
    await _setupController(_cameras[nextIndex]);
    HapticFeedback.selectionClick();
  }

  Future<void> _takePicture() async {
    if (_isCapturing) return;

    final controller = _controller;
    final hasLiveCamera = controller != null && controller.value.isInitialized;

    try {
      setState(() {
        _isCapturing = true;
        _statusMessage = hasLiveCamera
            ? 'Capturing high-res photo...'
            : 'Simulating camera capture...';
      });
      HapticFeedback.mediumImpact();

      if (hasLiveCamera) {
        final XFile photo = await controller.takePicture();
        try {
          await controller.pausePreview();
        } catch (_) {}
        if (!mounted) return;

        setState(() {
          _capturedImagePath = photo.path;
          _statusMessage = 'Running YOLOv8 AI model...';
        });

        // Run real on-device inference using best.tflite
        final result = await DetectionService.instance.processImage(
          photo.path,
          'camera',
        );

        // Save report to repository
        await ReportRepository.instance.addReport(result.report);

        if (mounted) {
          Navigator.of(context).pop(result);
        }
      } else {
        // Fallback simulation test
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        final result = await DetectionService.instance.simulateCapture();
        await ReportRepository.instance.addReport(result.report);

        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      debugPrint('Error capturing/analyzing photo: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedImagePath = null;
        });
        try {
          await controller?.resumePreview();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to analyze photo: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing) return;

    try {
      final path = await DetectionService.instance.pickGalleryPhoto();
      if (path != null && mounted) {
        try {
          await _controller?.pausePreview();
        } catch (_) {}
        setState(() {
          _isCapturing = true;
          _capturedImagePath = path;
          _statusMessage = 'Running YOLOv8 AI model...';
        });

        // Run on-device inference using best.tflite
        final result = await DetectionService.instance.processImage(
          path,
          'gallery',
        );

        // Save report to repository
        await ReportRepository.instance.addReport(result.report);

        if (mounted) {
          Navigator.of(context).pop(result);
        }
      }
    } catch (e) {
      debugPrint('Error analyzing gallery image: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _capturedImagePath = null;
        });
        try {
          await _controller?.resumePreview();
        } catch (_) {}
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to analyze gallery photo: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Frozen Photo
            _buildCameraPreview(),

            // AI Target Reticle HUD Overlay (only while scanning live feed)
            if (_capturedImagePath == null &&
                _controller != null &&
                _controller!.value.isInitialized)
              _buildTargetReticle(),

            // Top Bar Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // Bottom Shutter & Controls
            if (!_isCapturing)
              Positioned(
                bottom: 28,
                left: 0,
                right: 0,
                child: _buildBottomControls(),
              ),

            // Capturing & Analyzing Spinner Overlay
            if (_isCapturing)
              Container(
                color: Colors.black.withValues(alpha: 0.40),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 22,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.accentOrange.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            color: AppTheme.accentOrange,
                            strokeWidth: 3.2,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Inspecting road surface for damage...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_capturedImagePath != null && File(_capturedImagePath!).existsSync()) {
      return Image.file(
        File(_capturedImagePath!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (_initError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_rounded,
                color: AppTheme.textMuted,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Choose from Gallery'),
                onPressed: _pickFromGallery,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderMedium),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Run Test Simulation'),
                onPressed: _takePicture,
              ),
            ],
          ),
        ),
      );
    }

    if (_isInitializing ||
        _controller == null ||
        !_controller!.value.isInitialized) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppTheme.accentAmber),
            SizedBox(height: 16),
            Text(
              'Starting Road Camera...',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize?.height ?? 1080,
        height: _controller!.value.previewSize?.width ?? 1920,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildTargetReticle() {
    return Center(
      child: IgnorePointer(
        child: Container(
          width: 260,
          height: 260,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.accentAmber.withValues(alpha: 0.6),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Corner Accents
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.accentAmber, width: 3),
                      left: BorderSide(color: AppTheme.accentAmber, width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.accentAmber, width: 3),
                      right: BorderSide(color: AppTheme.accentAmber, width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.accentAmber, width: 3),
                      left: BorderSide(color: AppTheme.accentAmber, width: 3),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.accentAmber, width: 3),
                      right: BorderSide(color: AppTheme.accentAmber, width: 3),
                    ),
                  ),
                ),
              ),
              // AI Detection Helper Text
              Positioned(
                bottom: -26,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'FRAME ROAD DAMAGE & SNAP PHOTO',
                      style: TextStyle(
                        color: AppTheme.accentAmber,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
          ),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),

        // Camera Title Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accentOrange.withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.camera_alt_rounded,
                color: AppTheme.accentOrange,
                size: 14,
              ),
              SizedBox(width: 6),
              Text(
                'ROAD SCANNER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Torch Toggle
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.5),
          ),
          icon: Icon(
            _isTorchOn ? Icons.flash_on : Icons.flash_off,
            color: _isTorchOn ? AppTheme.accentAmber : Colors.white,
          ),
          onPressed: _toggleTorch,
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Gallery Shortcut
          GestureDetector(
            onTap: _pickFromGallery,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),

          // Big Shutter Button
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentOrange.withValues(alpha: 0.5),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppTheme.accentOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),

          // Flip Camera
          GestureDetector(
            onTap: _flipCamera,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.flip_camera_android_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
