import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Directional field-of-view gradient vision cone radiating from user location marker
class HeadingConePainter extends CustomPainter {
  final Color color;
  final double angleRadians;

  HeadingConePainter({
    required this.color,
    required this.angleRadians,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const sweepAngle = math.pi / 2.8;
    final startAngle = angleRadians - (sweepAngle / 2.0);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.40),
          color.withValues(alpha: 0.16),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant HeadingConePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.angleRadians != angleRadians;
  }
}
