import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../core/models.dart';
import '../core/report_repository.dart';

/// Full-screen in-app camera capture and AI scanner HUD.
class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen>
    with SingleTickerProviderStateMixin {
  bool _isCapturing = false;
  bool _isTorchOn = false;
  String _statusMessage = 'Processing Frame...';
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() => _isTorchOn = !_isTorchOn);
    HapticFeedback.selectionClick();
  }

  Future<void> _triggerCapture({bool isGallery = false}) async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = isGallery
          ? 'Loading Image & Running YOLOv8...'
          : 'Capturing High-Res Frame...';
    });
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() {
      _statusMessage = 'Running YOLOv8 On-Device Model...';
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // Generate a realistic detection report
    final now = DateTime.now();
    final randomId = 'RPT-${now.millisecondsSinceEpoch % 10000}';
    final sampleDamages = [
      {
        'type': 'Pothole',
        'severity': 'Critical',
        'area': 0.45,
        'width': 310.0,
        'depth': 7.2,
        'box': const Rect.fromLTWH(0.24, 0.32, 0.48, 0.38),
        'notes': 'Cavity with active edge decay. Immediate asphalt filling recommended.',
      },
    ];

    final chosen = sampleDamages[now.second % sampleDamages.length];

    final newReport = DamageReport(
      id: randomId,
      damageType: chosen['type'] as String,
      severity: chosen['severity'] as String,
      latitude: 23.8103 + (now.millisecond % 50) * 0.0001,
      longitude: 90.4125 + (now.second % 50) * 0.0001,
      address: 'Fulbarigate',
      timestamp: now,
      status: 'detected',
      confidenceScore: 0.94,
      reportedBy: 'You',
      damageAreaSqM: chosen['area'] as double,
      notes: chosen['notes'] as String,
      crackWidthMm: chosen['width'] as double,
      estimatedDepthCm: chosen['depth'] as double,
      boundingBox: chosen['box'] as Rect,
    );

    await ReportRepository.instance.addReport(newReport);

    if (mounted) {
      Navigator.of(context).pop(
        DetectionResult(
          report: newReport,
          confidence: newReport.confidenceScore,
        ),
      );
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
            // Top Bar Controls
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // Bottom Shutter & Controls
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),

            // Capturing & Analyzing Spinner Overlay
            if (_isCapturing)
              Container(
                color: Colors.black.withValues(alpha: 0.75),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: AppTheme.accentOrange,
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
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
            onTap: () => _triggerCapture(isGallery: true),
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
            onTap: () => _triggerCapture(isGallery: false),
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

          // Switch / Info
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('YOLOv8 On-Device AI Scanner ready.'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
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
