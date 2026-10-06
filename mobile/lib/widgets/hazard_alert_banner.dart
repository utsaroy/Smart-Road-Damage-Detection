import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/models.dart';

/// Banner widget for displaying an active hazard alert.
class HazardAlertBanner extends StatelessWidget {
  final HazardAlert alert;
  final VoidCallback? onTap;

  const HazardAlertBanner({super.key, required this.alert, this.onTap});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(alert.severity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: severityColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Warning icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                AppTheme.getSeverityIcon(alert.severity),
                color: severityColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          alert.address,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Distance badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: severityColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '${alert.distanceMeters.toInt()}m',
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'away',
                    style: TextStyle(
                      color: severityColor.withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
