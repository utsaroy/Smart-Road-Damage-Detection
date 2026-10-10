import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../core/theme.dart';
import '../core/models.dart';
import '../core/report_repository.dart';
import '../core/location_service.dart';
import '../core/compass_service.dart';
import '../core/alert_service.dart';
import '../widgets/jelly_badge.dart';
import '../widgets/heading_cone_painter.dart';
import 'full_screen_map.dart';
import 'profile_screen.dart';

/// Home screen — displays interactive hazard map preview and nearby hazards list.
/// Tapping the map opens the full-screen map view.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  LatLng _userLocation = LocationService.instance.lastKnownLocation;
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<double>? _compassSub;
  double _currentCompassHeading = CompassService.instance.currentHeading;
  String? _lastAlertedHazardId;
  DateTime? _lastAlertTime;

  String _selectedCategory = 'All';
  bool _radarActive = true;
  final String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCompass();
    _initUserLocation();
  }

  void _initCompass() {
    CompassService.instance.start();
    _currentCompassHeading = CompassService.instance.currentHeading;
    _compassSub = CompassService.instance.headingStream.listen((heading) {
      if (mounted) {
        setState(() => _currentCompassHeading = heading);
      }
    });
  }

  Future<void> _initUserLocation() async {
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = loc;
        });
        try {
          _mapController.move(loc, 15.0);
        } catch (_) {}
      }

      // Subscribe to real-time device movement
      _positionSub = LocationService.instance.getPositionStream()?.listen((
        pos,
      ) {
        if (mounted) {
          final newLoc = LatLng(pos.latitude, pos.longitude);
          setState(() {
            _userLocation = newLoc;
          });
          CompassService.instance.updateFromGpsCourse(pos.heading, pos.speed);
          _checkProximityHazards(newLoc, ReportRepository.instance);
        }
      });
    } catch (e) {
      debugPrint('HomeScreen: Error fetching GPS location: $e');
    }
  }

  void _checkProximityHazards(LatLng userLoc, ReportRepository repo) {
    if (!_radarActive) return;

    final alerts = repo.alertsInRadius;
    if (alerts.isEmpty) return;

    final activeHazards = alerts.where((a) => a.isActive).toList();
    if (activeHazards.isEmpty) return;

    activeHazards.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    final closest = activeHazards.first;

    if (repo.criticalOnlyAlerts &&
        closest.severity != 'Critical' &&
        closest.severity != 'High') {
      return;
    }

    final now = DateTime.now();
    if (_lastAlertedHazardId != closest.id ||
        _lastAlertTime == null ||
        now.difference(_lastAlertTime!).inSeconds > 25) {
      _lastAlertedHazardId = closest.id;
      _lastAlertTime = now;

      AlertService.triggerAlert(
        sound: repo.soundAlertsEnabled,
        vibrate: repo.vibrationEnabled,
        notification: repo.pushNotificationsEnabled,
        title: '${closest.severity} ${closest.damageType} Alert',
        message: '${closest.distanceMeters.toInt()}m away',
      );
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _openFullScreenMap({
    LatLng? focusLocation,
    MapHazardItem? selectedItem,
  }) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenMapScreen(
          initialFocusLocation: focusLocation ?? _userLocation,
          initialSelectedItem: selectedItem,
        ),
      ),
    );
  }

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
        final effectiveLocation = _userLocation;
        final nearbyHazards = repo.getNearbyHazards(effectiveLocation);
        final mapHazards = repo.getMapHazardItems(effectiveLocation);
        final userCaptureCount = repo.userCaptures.length;

        final displayedHazards = nearbyHazards.where((h) {
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            final matches =
                h.damageType.toLowerCase().contains(q) ||
                h.address.toLowerCase().contains(q) ||
                h.severity.toLowerCase().contains(q);
            if (!matches) return false;
          }
          if (_selectedCategory == 'All') return true;
          if (_selectedCategory == 'Potholes') {
            return h.damageType.toLowerCase().contains('pothole');
          }
          if (_selectedCategory == 'Cracks') {
            return h.damageType.toLowerCase().contains('crack');
          }
          if (_selectedCategory == 'Critical') {
            return h.severity == 'Critical' || h.severity == 'High';
          }
          return true;
        }).toList();

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Header with Date, Title, Search and Profile
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 3),
                            Text(
                              'Smart Road',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Circular Search Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {});
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
                                    Icons.refresh_rounded,
                                    size: 20,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Circular Profile Button
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileScreen(),
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
                                    Icons.person_outline_rounded,
                                    size: 21,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      // Live Map Preview Card
                      _buildMapPreviewCard(repo, mapHazards, userCaptureCount),
                      const SizedBox(height: 14),

                      // Radar radius control
                      _buildRadiusControl(repo),
                      const SizedBox(height: 22),

                      // "Nearby Hazards" Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Nearby Hazards',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.obsidianBlack.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${displayedHazards.length}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.obsidianBlack,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _openFullScreenMap();
                            },
                            child: const Text(
                              'View on map',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Quick Category / Filter Pill Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildPillChip('All', 'All Hazards'),
                            _buildPillChip('Potholes', 'Potholes'),
                            _buildPillChip('Cracks', 'Cracks'),
                            _buildPillChip('Critical', 'High Risk'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Nearby Hazards list
                      if (displayedHazards.isEmpty)
                        _buildEmptyHazardsState(repo)
                      else
                        ...displayedHazards.map(
                          (hazard) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildHazardCard(hazard),
                          ),
                        ),

                      const SizedBox(height: 110),
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

  Widget _buildPillChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = key);
        HapticFeedback.selectionClick();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.obsidianBlack : AppTheme.chipBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.obsidianBlack : AppTheme.chipBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textPrimary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Clickable live map preview card embedding FlutterMap with Dark Matrix tiles
  Widget _buildMapPreviewCard(
    ReportRepository repo,
    List<MapHazardItem> mapHazards,
    int userCaptureCount,
  ) {
    final displayCenter = _userLocation;

    return GestureDetector(
      onTap: () => _openFullScreenMap(focusLocation: displayCenter),
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: const Color.fromARGB(255, 135, 137, 141),
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Map preview centered on location
              IgnorePointer(
                child: FlutterMap(
                  key: const ValueKey('map_preview_key'),
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: displayCenter,
                    initialZoom: 15.0,
                    onMapReady: () {
                      try {
                        _mapController.move(displayCenter, 15.0);
                      } catch (_) {}
                    },
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.amar_path',
                      maxZoom: 19,
                      tileBuilder: (context, tileWidget, tile) {
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            -0.80,
                            0.0,
                            0.0,
                            0.0,
                            260.0,
                            0.0,
                            -0.80,
                            0.0,
                            0.0,
                            260.0,
                            0.0,
                            0.0,
                            -0.80,
                            0.0,
                            270.0,
                            0.0,
                            0.0,
                            0.0,
                            1.0,
                            0.0,
                          ]),
                          child: tileWidget,
                        );
                      },
                    ),
                    if (_radarActive)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: displayCenter,
                            radius: repo.alertRadius,
                            useRadiusInMeter: true,
                            color: AppTheme.accentAmber.withValues(alpha: 0.08),
                            borderColor: AppTheme.accentAmber.withValues(
                              alpha: 0.65,
                            ),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // Current User Marker (Rotates with phone compass direction)
                        Marker(
                          point: displayCenter,
                          width: 50,
                          height: 50,
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, _) {
                              final angleRad =
                                  (_currentCompassHeading - 90.0) *
                                  (math.pi / 180.0);
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Directional vision beam radiating in phone's direction
                                  CustomPaint(
                                    size: const Size(50, 50),
                                    painter: HeadingConePainter(
                                      color: Colors.blueAccent,
                                      angleRadians: angleRad,
                                    ),
                                  ),
                                  Container(
                                    width: 44 * _pulseAnimation.value,
                                    height: 44 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.withValues(
                                        alpha: 0.15,
                                      ),
                                      border: Border.all(
                                        color: Colors.blue.withValues(
                                          alpha: 0.4,
                                        ),
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                  // Blue center dot with rotating directional arrow
                                  Transform.rotate(
                                    angle: angleRad + (math.pi / 2.0),
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blueAccent,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withValues(
                                              alpha: 0.6,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.navigation,
                                          size: 8.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Real Hazard & Detection Pins (Perpendicular pin with ground disc)
                        ...mapHazards.map((hazard) {
                          final severityColor = AppTheme.getSeverityColor(
                            hazard.severity,
                          );
                          return Marker(
                            point: LatLng(hazard.latitude, hazard.longitude),
                            width: 36,
                            height: 36,
                            alignment: Alignment.topCenter,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 24,
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    Icon(
                                      Icons.location_on_rounded,
                                      size: 22,
                                      color: severityColor,
                                    ),
                                    if (hazard.isUserCapture)
                                      Positioned(
                                        top: 8,
                                        child: Container(
                                          width: 4.5,
                                          height: 4.5,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                Transform.translate(
                                  offset: const Offset(0, -5),
                                  child: Container(
                                    width: 12,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: severityColor.withValues(
                                        alpha: 0.35,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                        Radius.elliptical(12, 4.5),
                                      ),
                                      border: Border.all(
                                        color: severityColor.withValues(
                                          alpha: 0.85,
                                        ),
                                        width: 1.1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),

              // Radius and Live Compass badge on map
              Positioned(
                bottom: 10,
                left: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderMedium),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.track_changes,
                            size: 12,
                            color: AppTheme.aiLavender,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Radar: ${repo.alertRadius.toInt()}m',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderMedium),
                        boxShadow: AppTheme.cardShadow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 11,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentCompassHeading.toInt()}° ${CompassService.getHeadingCardinal(_currentCompassHeading)}',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Top right Full Screen CTA banner
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.obsidianBlack,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Full Map',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildRadiusControl(ReportRepository repo) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardLight,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderMedium, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Hazard Alert Radius',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _radarActive = !_radarActive);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _radarActive
                        ? AppTheme.lilacPill
                        : AppTheme.chipBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _radarActive
                            ? Icons.sensors_rounded
                            : Icons.sensors_off_rounded,
                        size: 13,
                        color: _radarActive
                            ? AppTheme.jellyPurpleColor
                            : AppTheme.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _radarActive ? 'ON' : 'OFF',
                        style: TextStyle(
                          color: _radarActive
                              ? AppTheme.jellyPurpleColor
                              : AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.aiLavender.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${repo.alertRadius.toInt()}m',
                  style: const TextStyle(
                    color: AppTheme.aiLavender,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.obsidianBlack,
              inactiveTrackColor: AppTheme.borderMedium,
              thumbColor: AppTheme.obsidianBlack,
              overlayColor: AppTheme.obsidianBlack.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: repo.alertRadius.clamp(10.0, 500.0),
              min: 10,
              max: 500,
              divisions: 49,
              onChanged: (value) {
                repo.setAlertRadius(value);
              },
            ),
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '10m (Near)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '500m (Far)',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHazardCard(MapHazardItem hazard) {
    final severityColor = AppTheme.getSeverityColor(hazard.severity);
    final hasImage =
        hazard.imagePath != null && File(hazard.imagePath!).existsSync();
    final timeStr = _formatTimeAgo(hazard.timestamp);
    final distStr = hazard.distanceMeters < 1000
        ? '${hazard.distanceMeters.toInt()}m'
        : '${(hazard.distanceMeters / 1000).toStringAsFixed(1)}km';

    return GestureDetector(
      onTap: () => _showHazardDetailDialog(hazard),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: hazard.isUserCapture
                ? AppTheme.obsidianBlack.withValues(alpha: 0.25)
                : AppTheme.borderLight,
            width: hazard.isUserCapture ? 1.5 : 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Left: 3D Frosted Jelly Squircle Badge or User Capture Thumbnail
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(hazard.imagePath!),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          JellyBadge.fromDamageType(
                            hazard.damageType,
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
                hazard.damageType,
                size: 48,
                iconSize: 22,
              ),
            const SizedBox(width: 14),

            // Middle Column: Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hazard.title.isNotEmpty
                              ? hazard.title
                              : hazard.damageType,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                        hazard.severity,
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                        '$distStr away',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Chevron '>'
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

  Widget _buildEmptyHazardsState(ReportRepository repo) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderMedium, width: 1.2),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 38,
            color: AppTheme.severityLow.withValues(alpha: 0.85),
          ),
          const SizedBox(height: 10),
          const Text(
            'Road Clear in Radius',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No active hazards within ${repo.alertRadius.toInt()}m. Expand radius or take a camera capture to scan the road.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.zoom_out_map_rounded, size: 14),
                label: const Text('Expand to 500m'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.obsidianBlack,
                  side: const BorderSide(color: AppTheme.borderMedium),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => repo.setAlertRadius(500),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.map_outlined, size: 14),
                label: const Text('Open Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.obsidianBlack,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () => _openFullScreenMap(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showHazardDetailDialog(MapHazardItem hazard) {
    final severityColor = AppTheme.getSeverityColor(hazard.severity);
    final hasImage =
        hazard.imagePath != null && File(hazard.imagePath!).existsSync();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
                    color: AppTheme.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Captured Photo if available
              if (hasImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    children: [
                      Image.file(
                        File(hazard.imagePath!),
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppTheme.accentOrange.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_camera,
                                size: 11,
                                color: AppTheme.accentAmber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Your Capture',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AppTheme.getSeverityIcon(hazard.severity),
                      color: severityColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hazard.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${hazard.distanceMeters < 1000 ? '${hazard.distanceMeters.toInt()}m' : '${(hazard.distanceMeters / 1000).toStringAsFixed(1)}km'} away • ${hazard.severity} Severity',
                          style: TextStyle(
                            color: severityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.place,
                          size: 15,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hazard.address,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.my_location,
                          size: 13,
                          color: AppTheme.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'GPS: ${hazard.latitude.toStringAsFixed(5)}, ${hazard.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Driver Advisory: Slow down and maintain safe following distance. Watch for road surface irregularities.',
                style: TextStyle(
                  color: AppTheme.textMuted.withValues(alpha: 0.9),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 15),
                      label: const Text('View on Map'),
                      onPressed: () {
                        Navigator.pop(context);
                        _openFullScreenMap(
                          focusLocation: LatLng(
                            hazard.latitude,
                            hazard.longitude,
                          ),
                          selectedItem: hazard,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.obsidianBlack,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
