import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Tactile 3D Frosted Jelly Squircle Badge with ambient colored under-glow.
/// Inspired by the playful, tactile VisionOS / Claymorphism aesthetic.
class JellyBadge extends StatelessWidget {
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final double size;
  final double iconSize;
  final double rotationDegrees;

  const JellyBadge({
    super.key,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    this.size = 46,
    this.iconSize = 22,
    this.rotationDegrees = 0,
  });

  /// Factory constructor for Pothole damage (Coral / Strawberry Jelly)
  factory JellyBadge.pothole({double size = 46, double iconSize = 22, double rotation = 0}) {
    return JellyBadge(
      icon: Icons.circle_outlined,
      gradient: AppTheme.jellyPink,
      glowColor: const Color(0xFFFF4D6D),
      size: size,
      iconSize: iconSize,
      rotationDegrees: rotation,
    );
  }

  /// Factory constructor for Longitudinal Crack (Sky / Ocean Blue Jelly)
  factory JellyBadge.longitudinalCrack({double size = 46, double iconSize = 22, double rotation = 0}) {
    return JellyBadge(
      icon: Icons.horizontal_rule_rounded,
      gradient: AppTheme.jellyBlue,
      glowColor: const Color(0xFF3B82F6),
      size: size,
      iconSize: iconSize,
      rotationDegrees: rotation,
    );
  }

  /// Factory constructor for Transverse Crack (Mango / Amber Jelly)
  factory JellyBadge.transverseCrack({double size = 46, double iconSize = 22, double rotation = 0}) {
    return JellyBadge(
      icon: Icons.more_vert_rounded,
      gradient: AppTheme.jellyAmber,
      glowColor: const Color(0xFFF59E0B),
      size: size,
      iconSize: iconSize,
      rotationDegrees: rotation,
    );
  }

  /// Factory constructor for Alligator Crack / Severe (Lilac / Rocket Jelly)
  factory JellyBadge.alligatorCrack({double size = 46, double iconSize = 22, double rotation = 0}) {
    return JellyBadge(
      icon: Icons.grid_view_rounded,
      gradient: AppTheme.jellyPurple,
      glowColor: const Color(0xFF7C5CFC),
      size: size,
      iconSize: iconSize,
      rotationDegrees: rotation,
    );
  }

  /// Factory constructor based on damage type string
  factory JellyBadge.fromDamageType(String type, {double size = 46, double iconSize = 22, double rotation = 0}) {
    final lower = type.toLowerCase();
    if (lower.contains('pothole')) {
      return JellyBadge.pothole(size: size, iconSize: iconSize, rotation: rotation);
    } else if (lower.contains('longitudinal')) {
      return JellyBadge.longitudinalCrack(size: size, iconSize: iconSize, rotation: rotation);
    } else if (lower.contains('transverse')) {
      return JellyBadge.transverseCrack(size: size, iconSize: iconSize, rotation: rotation);
    } else if (lower.contains('alligator')) {
      return JellyBadge.alligatorCrack(size: size, iconSize: iconSize, rotation: rotation);
    } else {
      return JellyBadge(
        icon: Icons.check_circle_outline_rounded,
        gradient: AppTheme.jellyMint,
        glowColor: const Color(0xFF10B981),
        size: size,
        iconSize: iconSize,
        rotationDegrees: rotation,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rad = rotationDegrees * math.pi / 180;

    Widget badge = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(size * 0.34),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.38),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white,
        ),
      ),
    );

    if (rotationDegrees != 0) {
      badge = Transform.rotate(angle: rad, child: badge);
    }

    return badge;
  }
}
