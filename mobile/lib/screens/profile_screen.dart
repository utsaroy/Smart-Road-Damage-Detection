import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme.dart';
import '../core/models.dart';
import '../core/report_repository.dart';
import '../core/alert_service.dart';
import '../core/report_sync_service.dart';
import '../widgets/section_header.dart';
import '../widgets/jelly_badge.dart';

/// Profile screen — shows activity overview, contribution overview,
/// recent inspections list, and comprehensive settings & system options.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final repo = ReportRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final stats = repo.stats;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Clean top header with back button and share button
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).pop();
                              },
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                    width: 1.2,
                                  ),
                                  boxShadow: AppTheme.cardShadow,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.arrow_back_rounded,
                                    size: 20,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Profile',
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.7,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Activity & System Settings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Share profile button
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Profile link copied to clipboard',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: AppTheme.borderLight,
                                width: 1.2,
                              ),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.share_outlined,
                                size: 19,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Identity Card
                      _buildProfileCard(),
                      const SizedBox(height: 22),

                      // 1. Activity Overview Section
                      const SectionHeader(
                        title: 'Activity Overview',
                        icon: Icons.insights_rounded,
                        iconColor: AppTheme.accentAmber,
                      ),
                      const SizedBox(height: 12),
                      _buildActivityMetricsTile(stats),
                      const SizedBox(height: 24),

                      // 2. Damage Analytics Section
                      const SectionHeader(
                        title: 'Damage Analytics',
                        icon: Icons.analytics_rounded,
                        iconColor: AppTheme.accentOrange,
                      ),
                      const SizedBox(height: 12),

                      // Damage Type Pie Chart
                      _buildDamageDistributionChart(repo),
                      const SizedBox(height: 16),

                      // Severity Breakdown Progress Bars
                      _buildSeverityBreakdownBars(repo),
                      const SizedBox(height: 24),

                      // 3. Recent Activity Section
                      const SectionHeader(
                        title: 'Recent Activity',
                        icon: Icons.history_rounded,
                        iconColor: AppTheme.aiLavender,
                      ),
                      const SizedBox(height: 12),
                      if (repo.reports.isEmpty)
                        _buildEmptyActivityCard()
                      else
                        ...repo.reports
                            .take(4)
                            .map(
                              (report) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildProfileReportCard(report, context),
                              ),
                            ),
                      const SizedBox(height: 24),

                      // 4. Settings & Options Section
                      const SectionHeader(
                        title: 'Hazard & Alert Settings',
                        icon: Icons.radar_rounded,
                        iconColor: AppTheme.accentAmber,
                      ),
                      const SizedBox(height: 12),
                      _buildAlertSettingsSection(repo, context),
                      const SizedBox(height: 20),

                      const SectionHeader(
                        title: 'Capture & Model Options',
                        icon: Icons.camera_alt_outlined,
                        iconColor: AppTheme.accentOrange,
                      ),
                      const SizedBox(height: 12),
                      _buildCaptureSettingsSection(repo, context),
                      const SizedBox(height: 20),

                      const SectionHeader(
                        title: 'System & Storage',
                        icon: Icons.settings_system_daydream,
                        iconColor: Colors.blueAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildSystemSettingsSection(context),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.obsidianBlack.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.obsidianBlack,
              boxShadow: AppTheme.cardShadow,
            ),
            child: const Center(
              child: Text(
                'UR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Utsa Roy',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        size: 14,
                        color: AppTheme.accentAmber,
                      ),
                      SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'utsaroy3@gmail.com',
                          style: TextStyle(
                            color: AppTheme.accentAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Activity Overview: Single unified tile displaying 4 key metrics
  Widget _buildActivityMetricsTile(UserStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.obsidianBlack.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildActivityStatItem(
                  title: 'Total Captures',
                  value: '${stats.totalCaptures}',
                  icon: Icons.camera_alt_outlined,
                  color: AppTheme.accentOrange,
                ),
              ),
              Container(width: 1, height: 44, color: AppTheme.borderLight),
              Expanded(
                child: _buildActivityStatItem(
                  title: 'Damages Found',
                  value: '${stats.detectedDamages}',
                  icon: Icons.search_rounded,
                  color: AppTheme.severityHigh,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Row(
            children: [
              Expanded(
                child: _buildActivityStatItem(
                  title: 'Distance Scanned',
                  value: '${stats.kmCovered} km',
                  icon: Icons.route_rounded,
                  color: AppTheme.longitudinalCrack,
                ),
              ),
              Container(width: 1, height: 44, color: AppTheme.borderLight),
              Expanded(
                child: _buildActivityStatItem(
                  title: 'Issues Resolved',
                  value: '${stats.resolvedIssues}',
                  icon: Icons.task_alt,
                  color: AppTheme.severityLow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Damage Type Pie Chart
  Widget _buildDamageDistributionChart(ReportRepository repo) {
    final Map<String, int> data = {};
    for (final r in repo.reports) {
      if (r.damageType.isNotEmpty &&
          r.damageType.toLowerCase() != 'no damage detected' &&
          r.damageType.toLowerCase() != 'clear road') {
        data[r.damageType] = (data[r.damageType] ?? 0) + 1;
      }
    }
    final total = data.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.borderMedium, width: 1.2),
          boxShadow: AppTheme.cardShadow,
        ),
        child: const Column(
          children: [
            Icon(Icons.pie_chart_outline, color: AppTheme.textMuted, size: 36),
            SizedBox(height: 10),
            Text(
              'No Damage Detections Yet',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Capture road photos to see AI damage classification breakdown.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderMedium, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Damage Type Distribution',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 5,
                child: SizedBox(
                  height: 160,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 28,
                      sections: data.entries.map((e) {
                        final color = AppTheme.getDamageTypeColor(e.key);
                        final percent = ((e.value / total) * 100).toInt();
                        return PieChartSectionData(
                          value: e.value.toDouble(),
                          color: color,
                          title: '$percent%',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          radius: 46,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.getDamageTypeColor(e.key),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.key} (${e.value})',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Severity Breakdown Progress Bars
  Widget _buildSeverityBreakdownBars(ReportRepository repo) {
    final Map<String, int> counts = {
      'Critical': 0,
      'High': 0,
      'Medium': 0,
      'Low': 0,
    };
    for (final r in repo.reports) {
      if (counts.containsKey(r.severity)) {
        counts[r.severity] = counts[r.severity]! + 1;
      }
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);

    if (total == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderMedium, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Severity Breakdown',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...counts.entries.map((e) {
            final percent = e.value / total;
            final color = AppTheme.getSeverityColor(e.key);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            e.key,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${e.value} (${(percent * 100).toInt()}%)',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: AppTheme.chipBackground,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Empty state placeholder for recent inspections
  Widget _buildEmptyActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderMedium, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: const Column(
        children: [
          Icon(Icons.history_toggle_off, color: AppTheme.textMuted, size: 36),
          SizedBox(height: 10),
          Text(
            'No Recent Activity',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Recorded inspections and road damage scans will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Recent Inspection card item
  Widget _buildProfileReportCard(DamageReport report, BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(report.severity);
    final hasPhoto =
        report.imagePath != null && File(report.imagePath!).existsSync();
    final timeStr = _formatTimeAgo(report.timestamp);

    final isGpsOrUnavailable =
        report.address.trim().startsWith('GPS') ||
        report.address.toLowerCase().contains('unavailable') ||
        report.address.toLowerCase().contains('unknown');
    final displayAddress = isGpsOrUnavailable ? null : report.address.trim();
    final showStatusBadge = report.status.toLowerCase() != 'detected';

    return GestureDetector(
      onTap: () => _showReportDetailDialog(report, context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppTheme.obsidianBlack.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(report.imagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          JellyBadge.fromDamageType(
                            report.damageType,
                            size: 48,
                            iconSize: 22,
                          ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppTheme.obsidianBlack,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(6),
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 9,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              JellyBadge.fromDamageType(
                report.damageType,
                size: 48,
                iconSize: 22,
              ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          report.damageType,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (showStatusBadge)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: report.statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: report.statusColor.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            report.status.toUpperCase(),
                            style: TextStyle(
                              color: report.statusColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
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
                      if (displayAddress != null) ...[
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
                        Expanded(
                          child: Text(
                            displayAddress,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 6),
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

  void _showReportDetailDialog(DamageReport report, BuildContext context) {
    final severityColor = AppTheme.getSeverityColor(report.severity);
    final hasImage =
        report.imagePath != null && File(report.imagePath!).existsSync();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(report.imagePath!),
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      report.damageType,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: severityColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      report.severity,
                      style: TextStyle(
                        color: severityColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.address,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.obsidianBlack,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Alert & Radar Settings
  Widget _buildAlertSettingsSection(
    ReportRepository repo,
    BuildContext context,
  ) {
    return Column(
      children: [
        _buildSettingToggleTile(
          icon: Icons.volume_up_outlined,
          title: 'Sound Alerts',
          subtitle: 'Play proximity alert audio when near critical hazards',
          value: repo.soundAlertsEnabled,
          onChanged: repo.toggleSoundAlerts,
        ),
        const SizedBox(height: 8),
        _buildSettingToggleTile(
          icon: Icons.vibration_rounded,
          title: 'Haptic Vibration',
          subtitle: 'Vibrate device upon entering hazard alert radius',
          value: repo.vibrationEnabled,
          onChanged: repo.toggleVibration,
        ),
        const SizedBox(height: 8),
        _buildSettingToggleTile(
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          subtitle: 'Receive background alerts when driving near hazards',
          value: repo.pushNotificationsEnabled,
          onChanged: repo.togglePushNotifications,
        ),
        const SizedBox(height: 8),
        _buildSettingToggleTile(
          icon: Icons.filter_alt_outlined,
          title: 'Critical Only Filter',
          subtitle: 'Only sound warnings for Critical & High damage',
          value: repo.criticalOnlyAlerts,
          onChanged: repo.toggleCriticalOnly,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.volume_up_rounded, size: 20),
            label: const Text('Test Proximity Alert'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: AppTheme.obsidianBlack,
              side: const BorderSide(color: AppTheme.borderMedium),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () async {
              final sound = repo.soundAlertsEnabled;
              final vibrate = repo.vibrationEnabled;
              final push = repo.pushNotificationsEnabled;

              final allOff = !sound && !vibrate && !push;
              final willPlaySound = sound || allOff;
              final willVibrate = vibrate || allOff;
              final willPush = push || allOff;

              await AlertService.triggerAlert(
                sound: willPlaySound,
                vibrate: willVibrate,
                notification: willPush,
                title: 'Road Hazard Alert (Test)',
                message:
                    'Proximity detection active. Pothole detected 50m ahead.',
              );

              if (context.mounted) {
                final channels = [
                  if (willPlaySound) 'Sound',
                  if (willVibrate) 'Vibration',
                  if (willPush) 'Push Notification',
                ].join(' + ');

                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Alert Triggered: $channels operational!'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  /// Capture & Model Options
  Widget _buildCaptureSettingsSection(
    ReportRepository repo,
    BuildContext context,
  ) {
    return Column(children: [_buildModelManagementCard(context)]);
  }

  /// Model Information Card
  Widget _buildModelManagementCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight, width: 1.3),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.aiLavender.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.memory_rounded,
                  size: 22,
                  color: AppTheme.obsidianBlack,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'best.tflite (YOLOv8 On-Device)',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pre-trained Model(12.4 MB)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.severityLow.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.severityLow.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: AppTheme.severityLow,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Architectural Specs Grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight, width: 1),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecItem(
                        label: 'Resolution',
                        value: '640 × 640 px',
                        icon: Icons.aspect_ratio_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppTheme.borderMedium,
                    ),
                    Expanded(
                      child: _buildSpecItem(
                        label: 'Layout',
                        value: 'NCHW (Planar)',
                        icon: Icons.layers_rounded,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16, color: AppTheme.borderLight),
                Row(
                  children: [
                    Expanded(
                      child: _buildSpecItem(
                        label: 'Tensors',
                        value: '1 × 8 × 8400',
                        icon: Icons.grid_view_rounded,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppTheme.borderMedium,
                    ),
                    Expanded(
                      child: _buildSpecItem(
                        label: 'Classes',
                        value: '1 damage types',
                        icon: Icons.category_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// System Settings Section
  Widget _buildSystemSettingsSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuTile(
          icon: Icons.cloud_sync_outlined,
          title: 'Authority Database Sync',
          subtitle: ReportSyncService.instance.serverBaseUrl,
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 32),
              backgroundColor: AppTheme.accentIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              final count = await ReportSyncService.instance.syncAllLocalReports();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Synced $count detection(s) to website database.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Sync', style: TextStyle(fontSize: 11)),
          ),
        ),
        const SizedBox(height: 8),

        _buildMenuTile(
          icon: Icons.storage_outlined,
          title: 'Stored Inspections',
          subtitle:
              '${ReportRepository.instance.reports.length} road damage records in active session',
        ),
        const SizedBox(height: 8),

        _buildMenuTile(
          icon: Icons.delete_sweep_outlined,
          title: 'Reset Inspection History',
          subtitle: 'Clear all session captures and reload sample records',
          isDestructive: true,
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 32),
              side: BorderSide(
                color: AppTheme.severityHigh.withValues(alpha: 0.6),
              ),
              foregroundColor: AppTheme.severityHigh,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Session inspections reset.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset', style: TextStyle(fontSize: 11)),
          ),
        ),
        const SizedBox(height: 8),

        _buildMenuTile(
          icon: Icons.info_outline_rounded,
          title: 'About Smart Road System',
          subtitle: 'v1.0.0+1 • Real-time AI Hazard Detection',
        ),
      ],
    );
  }

  Widget _buildSettingToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.chipBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              onChanged(val);
              HapticFeedback.lightImpact();
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.obsidianBlack,
            inactiveTrackColor: AppTheme.borderMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDestructive
                ? AppTheme.severityHigh.withValues(alpha: 0.3)
                : AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.severityHigh.withValues(alpha: 0.1)
                    : AppTheme.chipBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isDestructive
                    ? AppTheme.severityHigh
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? AppTheme.severityHigh
                          : AppTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
          ],
        ),
      ),
    );
  }
}
