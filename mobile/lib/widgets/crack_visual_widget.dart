import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';

/// Renders either the real captured image file or a procedural asphalt canvas
/// with mathematically exact AI bounding boxes, corner brackets, and confidence badges.
class CrackVisualWidget extends StatefulWidget {
  final DamageReport report;
  final double height;
  final double? width;
  final bool showBoundingBox;
  final bool isThumbnail;
  final BoxFit initialFit;

  const CrackVisualWidget({
    super.key,
    required this.report,
    this.height = 220,
    this.width,
    this.showBoundingBox = true,
    this.isThumbnail = false,
    this.initialFit = BoxFit.contain,
  });

  @override
  State<CrackVisualWidget> createState() => _CrackVisualWidgetState();
}

class _CrackVisualWidgetState extends State<CrackVisualWidget> {
  int? _imageWidth;
  int? _imageHeight;
  late BoxFit _currentFit;

  @override
  void initState() {
    super.initState();
    _currentFit = widget.isThumbnail ? BoxFit.cover : widget.initialFit;
    _resolveImageDimensions();
  }

  @override
  void didUpdateWidget(covariant CrackVisualWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.imagePath != widget.report.imagePath) {
      _resolveImageDimensions();
    }
  }

  void _resolveImageDimensions() {
    if (widget.report.imageWidth != null && widget.report.imageHeight != null) {
      _imageWidth = widget.report.imageWidth;
      _imageHeight = widget.report.imageHeight;
      return;
    }

    final path = widget.report.imagePath;
    if (path == null || path.isEmpty || !File(path).existsSync()) return;

    final imageProvider = FileImage(File(path));
    final stream = imageProvider.resolve(ImageConfiguration.empty);
    late ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo info, bool _) {
        if (mounted) {
          setState(() {
            _imageWidth = info.image.width;
            _imageHeight = info.image.height;
          });
        }
        stream.removeListener(listener);
      },
      onError: (dynamic error, StackTrace? stack) {
        stream.removeListener(listener);
      },
    );

    stream.addListener(listener);
  }

  void _toggleFit() {
    setState(() {
      _currentFit = _currentFit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
    });
  }

  void _openFullScreenViewer() {
    final path = widget.report.imagePath;
    if (path == null || !File(path).existsSync()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenDamageViewer(
          report: widget.report,
          imageWidth: _imageWidth,
          imageHeight: _imageHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasRealImage = widget.report.imagePath != null &&
        widget.report.imagePath!.isNotEmpty &&
        File(widget.report.imagePath!).existsSync();

    final severityColor = AppTheme.getSeverityColor(widget.report.severity);
    final damageColor = AppTheme.getDamageTypeColor(widget.report.damageType);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.isThumbnail ? 10 : 16),
      child: Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF0D1219),
          border: Border.all(
            color: severityColor.withValues(alpha: widget.isThumbnail ? 0.2 : 0.4),
            width: 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Base visual: Real photo or procedural canvas
            if (hasRealImage)
              GestureDetector(
                onTap: widget.isThumbnail ? null : _openFullScreenViewer,
                child: Image.file(
                  File(widget.report.imagePath!),
                  fit: _currentFit,
                  cacheWidth: widget.isThumbnail ? 200 : 1080,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildProceduralCanvas(damageColor, severityColor),
                ),
              )
            else
              _buildProceduralCanvas(damageColor, severityColor),

            // 2. Mathematically Exact AI Bounding Box overlay
            if (widget.showBoundingBox && !widget.isThumbnail)
              _buildExactBoundingBoxOverlay(damageColor, severityColor),

            // 3. Top badge
            if (!widget.isThumbnail)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: damageColor.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: severityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI DETECT: ${widget.report.damageType.toUpperCase()}',
                        style: TextStyle(
                          color: damageColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 4. View Mode & Fullscreen Controls
            if (!widget.isThumbnail && hasRealImage)
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fit toggle button
                    Material(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: _toggleFit,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _currentFit == BoxFit.contain
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                size: 13,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _currentFit == BoxFit.contain ? 'Fit' : 'Fill',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Expand/Zoom icon
                    Material(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: _openFullScreenViewer,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Icon(
                            Icons.zoom_in,
                            size: 14,
                            color: AppTheme.accentAmber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Confidence chip at bottom right
            if (!widget.isThumbnail)
              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    widget.report.confidenceScore > 0
                        ? '${(widget.report.confidenceScore * 100).toInt()}% Conf.'
                        : 'Clear Surface',
                    style: TextStyle(
                      color: widget.report.confidenceScore > 0
                          ? AppTheme.accentAmber
                          : AppTheme.severityLow,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceduralCanvas(Color damageColor, Color severityColor) {
    return CustomPaint(
      painter: _ProceduralCrackPainter(
        damageType: widget.report.damageType,
        severity: widget.report.severity,
        damageColor: damageColor,
        isThumbnail: widget.isThumbnail,
      ),
    );
  }

  /// Exact bounding boxes mapped through applyBoxFit to match the rendered image pixels
  Widget _buildExactBoundingBoxOverlay(Color damageColor, Color severityColor) {
    final detections = widget.report.detections.isNotEmpty
        ? widget.report.detections
        : (widget.report.boundingBox != null
            ? [
                DetectedHazard(
                  rect: widget.report.boundingBox!,
                  confidence: widget.report.confidenceScore,
                  label: widget.report.damageType,
                ),
              ]
            : <DetectedHazard>[]);

    if (detections.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        final List<Widget> boxWidgets = [];

        for (int i = 0; i < detections.length; i++) {
          final hazard = detections[i];
          final rawRect = hazard.rect;
          Rect boxOnScreen;

          if (_imageWidth != null &&
              _imageHeight != null &&
              _imageWidth! > 0 &&
              _imageHeight! > 0) {
            final imageSize =
                Size(_imageWidth!.toDouble(), _imageHeight!.toDouble());
            final fitted = applyBoxFit(_currentFit, imageSize, containerSize);

            final sourceRect = Alignment.center.inscribe(
              fitted.source,
              Offset.zero & imageSize,
            );
            final destinationRect = Alignment.center.inscribe(
              fitted.destination,
              Offset.zero & containerSize,
            );

            final scaleX = destinationRect.width / sourceRect.width;
            final scaleY = destinationRect.height / sourceRect.height;

            final boxLeft = destinationRect.left +
                (rawRect.left * imageSize.width - sourceRect.left) * scaleX;
            final boxTop = destinationRect.top +
                (rawRect.top * imageSize.height - sourceRect.top) * scaleY;
            final boxWidth = (rawRect.width * imageSize.width) * scaleX;
            final boxHeight = (rawRect.height * imageSize.height) * scaleY;

            boxOnScreen = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxHeight);
          } else {
            // Fallback if image size is still loading
            boxOnScreen = Rect.fromLTWH(
              rawRect.left * containerSize.width,
              rawRect.top * containerSize.height,
              rawRect.width * containerSize.width,
              rawRect.height * containerSize.height,
            );
          }

          final labelText = detections.length > 1
              ? '#${i + 1} ${hazard.label}'
              : hazard.label;

          boxWidgets.add(
            Positioned(
              left: boxOnScreen.left,
              top: boxOnScreen.top,
              width: math.max(1.0, boxOnScreen.width),
              height: math.max(1.0, boxOnScreen.height),
              child: CustomPaint(
                painter: _CornerBracketPainter(
                  color: severityColor,
                  tag: '${(hazard.confidence * 100).toInt()}%',
                  label: labelText,
                ),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: boxWidgets,
        );
      },
    );
  }
}

/// Fullscreen zoomable damage inspector with multi-hazard bounding boxes
class _FullScreenDamageViewer extends StatelessWidget {
  final DamageReport report;
  final int? imageWidth;
  final int? imageHeight;

  const _FullScreenDamageViewer({
    required this.report,
    this.imageWidth,
    this.imageHeight,
  });

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(report.severity);
    final detections = report.detections.isNotEmpty
        ? report.detections
        : (report.boundingBox != null
            ? [
                DetectedHazard(
                  rect: report.boundingBox!,
                  confidence: report.confidenceScore,
                  label: report.damageType,
                ),
              ]
            : <DetectedHazard>[]);

    final titleText = report.hasMultipleDefects
        ? '${report.defectCount} Hazards Inspection'
        : '${report.damageType} Inspection';

    final badgeText = report.hasMultipleDefects
        ? '${report.defectCount} Detected'
        : '${(report.confidenceScore * 100).toInt()}% Conf.';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          titleText,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: severityColor),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5.0,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerSize =
                  Size(constraints.maxWidth, constraints.maxHeight);
              final imgW = (imageWidth ?? 640).toDouble();
              final imgH = (imageHeight ?? 640).toDouble();
              final imageSize = Size(imgW, imgH);

              final fitted =
                  applyBoxFit(BoxFit.contain, imageSize, containerSize);
              final destinationRect = Alignment.center.inscribe(
                fitted.destination,
                Offset.zero & containerSize,
              );

              final List<Widget> stackChildren = [
                Positioned.fromRect(
                  rect: destinationRect,
                  child: Image.file(
                    File(report.imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ];

              for (int i = 0; i < detections.length; i++) {
                final hazard = detections[i];
                final rawRect = hazard.rect;
                final labelText = detections.length > 1
                    ? '#${i + 1} ${hazard.label}'
                    : hazard.label;

                stackChildren.add(
                  Positioned(
                    left: destinationRect.left +
                        rawRect.left * destinationRect.width,
                    top: destinationRect.top +
                        rawRect.top * destinationRect.height,
                    width: rawRect.width * destinationRect.width,
                    height: rawRect.height * destinationRect.height,
                    child: CustomPaint(
                      painter: _CornerBracketPainter(
                        color: severityColor,
                        tag: '${(hazard.confidence * 100).toInt()}%',
                        label: labelText,
                      ),
                    ),
                  ),
                );
              }

              return Stack(
                children: stackChildren,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter for asphalt surface with realistic damage patterns
class _ProceduralCrackPainter extends CustomPainter {
  final String damageType;
  final String severity;
  final Color damageColor;
  final bool isThumbnail;

  _ProceduralCrackPainter({
    required this.damageType,
    required this.severity,
    required this.damageColor,
    required this.isThumbnail,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Asphalt base texture
    final asphaltPaint = Paint()..color = const Color(0xFF1B222D);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), asphaltPaint);

    final grainPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;

    for (int i = 0; i < (isThumbnail ? 30 : 90); i++) {
      final x = (i * 37) % size.width;
      final y = (i * 59) % size.height;
      canvas.drawCircle(Offset(x, y), (i % 3) * 0.8 + 0.5, grainPaint);
    }

    final lanePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = isThumbnail ? 3 : 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.15, size.height),
      lanePaint,
    );

    final crackGlow = Paint()
      ..color = damageColor.withValues(alpha: 0.25)
      ..strokeWidth = isThumbnail ? 6 : 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crackPaint = Paint()
      ..color = damageColor
      ..strokeWidth = isThumbnail ? 2.5 : 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final crackCore = Paint()
      ..color = const Color(0xFF0B0E14)
      ..strokeWidth = isThumbnail ? 1.5 : 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (damageType.toLowerCase()) {
      case 'pothole':
        final potholeRect = Rect.fromCenter(
          center: Offset(cx, cy),
          width: size.width * (isThumbnail ? 0.6 : 0.45),
          height: size.height * (isThumbnail ? 0.6 : 0.45),
        );
        final glowP = Paint()
          ..color = damageColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawOval(potholeRect.inflate(12), glowP);

        final craterP = Paint()
          ..color = const Color(0xFF0F131A)
          ..style = PaintingStyle.fill;
        canvas.drawOval(potholeRect, craterP);

        final rimP = Paint()
          ..color = damageColor.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawOval(potholeRect, rimP);
        break;

      case 'alligator crack':
        final path = Path();
        final points = [
          Offset(cx - 30, cy - 25),
          Offset(cx + 10, cy - 35),
          Offset(cx + 40, cy - 10),
          Offset(cx + 25, cy + 25),
          Offset(cx - 20, cy + 30),
          Offset(cx - 40, cy + 5),
        ];

        path.moveTo(points[0].dx, points[0].dy);
        for (int i = 1; i < points.length; i++) {
          path.lineTo(points[i].dx, points[i].dy);
        }
        path.close();

        path.moveTo(points[0].dx, points[0].dy);
        path.lineTo(points[3].dx, points[3].dy);
        path.moveTo(points[1].dx, points[1].dy);
        path.lineTo(points[4].dx, points[4].dy);
        path.moveTo(points[2].dx, points[2].dy);
        path.lineTo(points[5].dx, points[5].dy);

        canvas.drawPath(path, crackGlow);
        canvas.drawPath(path, crackPaint);
        canvas.drawPath(path, crackCore);
        break;

      case 'transverse crack':
        final path = Path();
        path.moveTo(size.width * 0.15, cy - 10);
        path.lineTo(size.width * 0.35, cy + 12);
        path.lineTo(size.width * 0.50, cy - 8);
        path.lineTo(size.width * 0.70, cy + 15);
        path.lineTo(size.width * 0.85, cy - 5);

        path.moveTo(size.width * 0.50, cy - 8);
        path.lineTo(size.width * 0.55, cy - 28);

        canvas.drawPath(path, crackGlow);
        canvas.drawPath(path, crackPaint);
        canvas.drawPath(path, crackCore);
        break;

      case 'longitudinal crack':
      default:
        final path = Path();
        path.moveTo(cx - 15, size.height * 0.15);
        path.lineTo(cx + 10, size.height * 0.35);
        path.lineTo(cx - 8, size.height * 0.55);
        path.lineTo(cx + 15, size.height * 0.75);
        path.lineTo(cx, size.height * 0.88);

        path.moveTo(cx + 10, size.height * 0.35);
        path.lineTo(cx + 35, size.height * 0.45);

        canvas.drawPath(path, crackGlow);
        canvas.drawPath(path, crackPaint);
        canvas.drawPath(path, crackCore);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints bounding box with high-visibility corner brackets, fill glow, and classification label
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final String tag;
  final String? label;

  _CornerBracketPainter({
    required this.color,
    required this.tag,
    this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;

    // 1. Outer subtle bounding border
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      borderPaint,
    );

    // 2. Translucent highlight fill
    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(4),
      ),
      fillPaint,
    );

    // 3. Thick neon corner brackets
    final cornerPaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final len = (math.min(size.width, size.height) * 0.28).clamp(8.0, 18.0);

    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(len, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), Offset(0, len), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), cornerPaint);

    // 4. Pill badge label
    final tagText = label != null ? '$label $tag' : tag;
    final textSpan = TextSpan(
      text: tagText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeH = textPainter.height + 4;
    final badgeW = textPainter.width + 10;
    final badgeTop = -badgeH - 2;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, badgeTop, badgeW, badgeH),
      const Radius.circular(4),
    );
    canvas.drawRRect(badgeRect, Paint()..color = color.withValues(alpha: 0.95));
    textPainter.paint(canvas, Offset(5, badgeTop + 2));
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.tag != tag || oldDelegate.label != label;
}
