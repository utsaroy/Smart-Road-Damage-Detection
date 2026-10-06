import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import 'jelly_badge.dart';

/// Tactile 3D Claymorphic Folder Card matching the central hero widget in the reference image.
/// Displays floating frosted 3D jelly squircle badges popping out of an embossed folder,
/// a count pill badge, and an interactive pill switch toggle.
class TactileVaultCard extends StatefulWidget {
  final int totalCount;
  final bool isRadarActive;
  final ValueChanged<bool>? onRadarToggle;
  final VoidCallback? onTap;

  const TactileVaultCard({
    super.key,
    required this.totalCount,
    this.isRadarActive = true,
    this.onRadarToggle,
    this.onTap,
  });

  @override
  State<TactileVaultCard> createState() => _TactileVaultCardState();
}

class _TactileVaultCardState extends State<TactileVaultCard> {
  late bool _radarActive;

  @override
  void initState() {
    super.initState();
    _radarActive = widget.isRadarActive;
  }

  @override
  void didUpdateWidget(covariant TactileVaultCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRadarActive != widget.isRadarActive) {
      _radarActive = widget.isRadarActive;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 196,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Layer 1: Back Card of the Folder (Layered sheet inside)
            Positioned(
              top: 14,
              left: 12,
              right: 12,
              child: Container(
                height: 168,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2F6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFE4E7ED),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 2: Floating 3D Frosted Jelly Badges popping out behind the folder flap
            Positioned(
              top: -6,
              child: SizedBox(
                width: 220,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Pink / Pothole Jelly
                    JellyBadge.pothole(
                      size: 46,
                      iconSize: 22,
                      rotation: -9,
                    ),
                    const SizedBox(width: 10),
                    // Blue / Crack Jelly
                    JellyBadge.longitudinalCrack(
                      size: 50,
                      iconSize: 24,
                      rotation: 4,
                    ),
                    const SizedBox(width: 10),
                    // Purple / Hazard Rocket Jelly
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: JellyBadge.alligatorCrack(
                        size: 46,
                        iconSize: 22,
                        rotation: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Layer 3: Tactile 3D Embossed Front Flap with Folder Tab
            Positioned(
              top: 36,
              left: 6,
              right: 6,
              bottom: 0,
              child: CustomPaint(
                painter: FolderPainter(
                  tabWidthRatio: 0.44,
                  tabStepDown: 18.0,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 38, 22, 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Circular Counter Pill on the left
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF4F5F8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                            const BoxShadow(
                              color: Colors.white,
                              blurRadius: 4,
                              offset: Offset(0, -1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '${widget.totalCount}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),

                      // Pill Switch Toggle on the right ("Radar" / "Off")
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() => _radarActive = !_radarActive);
                          widget.onRadarToggle?.call(_radarActive);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _radarActive
                                ? const Color(0xFFE9E3FE)
                                : const Color(0xFFECEEF2),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 12, right: 10),
                                child: Text(
                                  _radarActive ? 'Radar' : 'Off',
                                  style: TextStyle(
                                    color: _radarActive
                                        ? const Color(0xFF6E4BF5)
                                        : AppTheme.textMuted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.14),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    _radarActive
                                        ? Icons.radar_rounded
                                        : Icons.power_settings_new_rounded,
                                    size: 17,
                                    color: _radarActive
                                        ? const Color(0xFF6E4BF5)
                                        : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}

/// Custom painter that draws the authentic tactile folder flap silhouette
/// with top-left tab, smooth S-curve transition, white porcelain fill, and soft clay drop shadow.
class FolderPainter extends CustomPainter {
  final double tabWidthRatio;
  final double tabStepDown;

  FolderPainter({
    required this.tabWidthRatio,
    required this.tabStepDown,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const r = 26.0;
    final tabW = w * tabWidthRatio;
    final step = tabStepDown;

    final path = Path();
    // Bottom left corner
    path.moveTo(0, h - r);
    path.quadraticBezierTo(0, h, r, h);
    // Bottom edge
    path.lineTo(w - r, h);
    path.quadraticBezierTo(w, h, w, h - r);
    // Right edge up to lower top edge
    path.lineTo(w, step + r);
    path.quadraticBezierTo(w, step, w - r, step);
    // Lower top edge towards the tab transition
    path.lineTo(tabW + 24, step);
    // Smooth S-curve transition up to top of tab
    path.cubicTo(
      tabW + 10, step,
      tabW + 12, 0,
      tabW - 4, 0,
    );
    // Top edge of tab
    path.lineTo(r, 0);
    path.quadraticBezierTo(0, 0, 0, r);
    // Left edge down
    path.lineTo(0, h - r);
    path.close();

    // 1. Soft Clay Ambient Shadow
    final shadowPaint1 = Paint()
      ..color = Colors.black.withValues(alpha: 0.07)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.save();
    canvas.translate(0, 8);
    canvas.drawPath(path, shadowPaint1);
    canvas.restore();

    final shadowPaint2 = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.save();
    canvas.translate(0, 3);
    canvas.drawPath(path, shadowPaint2);
    canvas.restore();

    // 2. White Porcelain Fill
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 3. Subtle Bevel / Stroke
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FolderPainter oldDelegate) =>
      oldDelegate.tabWidthRatio != tabWidthRatio ||
      oldDelegate.tabStepDown != tabStepDown;
}
