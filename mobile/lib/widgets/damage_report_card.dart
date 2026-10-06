import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/models.dart';
import 'jelly_badge.dart';

/// Card widget matching the "Recent" list cards in the Clay & Frosted Jelly reference.
/// Features a tactile 3D frosted jelly badge with ambient glow and clean typography.
class DamageReportCard extends StatelessWidget {
  final DamageReport report;
  final VoidCallback? onTap;

  const DamageReportCard({super.key, required this.report, this.onTap});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(report.severity);
    final timeStr = DateFormat('MMM d, h:mm a').format(report.timestamp);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderLight, width: 1.2),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // 3D Frosted Jelly Squircle Badge with ambient glow
            JellyBadge.fromDamageType(
              report.damageType,
              size: 46,
              iconSize: 21,
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    report.damageType,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        report.severity,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Chevron Arrow
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
