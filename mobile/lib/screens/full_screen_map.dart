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

/// Full screen interactive hazard map screen displaying all detected road damages,
/// user camera captures, and radar hazard alerts.
class FullScreenMapScreen extends StatefulWidget {
  final LatLng? initialFocusLocation;
  final MapHazardItem? initialSelectedItem;
  final String initialMapStyle;

  const FullScreenMapScreen({
    super.key,
    this.initialFocusLocation,
    this.initialSelectedItem,
    this.initialMapStyle = 'streets',
  });

  @override
  State<FullScreenMapScreen> createState() => _FullScreenMapScreenState();
}

class _FullScreenMapScreenState extends State<FullScreenMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  LatLng _userLocation = LocationService.instance.lastKnownLocation;
  StreamSubscription<Position>? _positionSub;
  final double _currentCompassHeading = 42.0;

  MapHazardItem? _selectedItem;
  final bool _showRadiusRing = true;
  String _mapStyle = 'streets'; // 'streets', 'dark', 'satellite'

  @override
  void initState() {
    super.initState();
    _mapStyle = widget.initialMapStyle;
    _mapController = MapController();

    if (widget.initialSelectedItem != null) {
      _selectedItem = widget.initialSelectedItem;
    }

    if (widget.initialFocusLocation != null) {
      _userLocation = widget.initialFocusLocation!;
    }

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initLiveLocation();
  }

  Future<void> _initLiveLocation() async {
    try {
      if (widget.initialFocusLocation == null) {
        final loc = await LocationService.instance.getCurrentLocation();
        if (mounted) {
          setState(() => _userLocation = loc);
          try {
            _mapController.move(loc, 15.5);
          } catch (_) {}
        }
      }

      _positionSub =
          LocationService.instance.getPositionStream()?.listen((pos) {
        if (mounted) {
          setState(() {
            _userLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _getHeadingCardinal(double deg) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((deg + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }

  Future<void> _recenterGps() async {
    HapticFeedback.selectionClick();
    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() => _userLocation = loc);
        _mapController.move(loc, 16.0);
        _showToast('Centered on your GPS location');
      }
    } catch (_) {
      _mapController.move(_userLocation, 16.0);
      _showToast('Centered on last known location');
    }
  }

  void _cycleMapStyle() {
    setState(() {
      if (_mapStyle == 'streets') {
        _mapStyle = 'dark';
      } else if (_mapStyle == 'dark') {
        _mapStyle = 'satellite';
      } else {
        _mapStyle = 'streets';
      }
    });
    HapticFeedback.selectionClick();
    _showToast(
      _mapStyle == 'streets'
          ? 'Streets Map (Light Theme)'
          : (_mapStyle == 'dark'
              ? 'Dark Radar Map'
              : 'Satellite (ESRI World Imagery)'),
    );
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getTileUrl() {
    switch (_mapStyle) {
      case 'satellite':
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case 'streets':
      case 'dark':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ReportRepository.instance;

    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        final allItems = repo.getMapHazardItems(_userLocation);
        final userCaptureCount = allItems.where((i) => i.isUserCapture).length;

        // Hazards within current user radius
        final hazardsInRadius = allItems
            .where((i) => i.distanceMeters <= repo.alertRadius)
            .toList();
        hazardsInRadius.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
        final hasHazardInRadius = hazardsInRadius.isNotEmpty;
        final closestHazard = hasHazardInRadius ? hazardsInRadius.first : null;
        final alertSeverityColor = hasHazardInRadius
            ? AppTheme.getSeverityColor(closestHazard!.severity)
            : AppTheme.accentAmber;

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: Stack(
            children: [
              // Interactive Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _userLocation,
                  initialZoom: 15.0,
                  minZoom: 3.0,
                  maxZoom: 19.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                  onMapReady: () {
                    if (widget.initialFocusLocation != null) {
                      try {
                        _mapController.move(widget.initialFocusLocation!, 16.5);
                      } catch (_) {}
                    }
                  },
                  onTap: (tapPosition, point) {
                    if (_selectedItem != null) {
                      setState(() => _selectedItem = null);
                    }
                  },
                ),
                children: [
                  // Map Tiles
                  TileLayer(
                    urlTemplate: _getTileUrl(),
                    userAgentPackageName: 'com.example.amar_path',
                    maxZoom: 19,
                    tileBuilder: _mapStyle == 'dark'
                        ? (context, tileWidget, tile) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix(<double>[
                                -0.80, 0.0, 0.0, 0.0, 260.0,
                                0.0, -0.80, 0.0, 0.0, 260.0,
                                0.0, 0.0, -0.80, 0.0, 270.0,
                                0.0, 0.0, 0.0, 1.0, 0.0,
                              ]),
                              child: tileWidget,
                            );
                          }
                        : null,
                  ),

                  // Radar Radius Circle Layer
                  if (_showRadiusRing)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _userLocation,
                          radius: repo.alertRadius,
                          useRadiusInMeter: true,
                          color: hasHazardInRadius
                              ? alertSeverityColor.withValues(alpha: 0.10)
                              : AppTheme.accentAmber.withValues(alpha: 0.08),
                          borderColor: hasHazardInRadius
                              ? alertSeverityColor.withValues(alpha: 0.75)
                              : AppTheme.accentAmber.withValues(alpha: 0.65),
                          borderStrokeWidth: hasHazardInRadius ? 2.5 : 2.0,
                        ),
                      ],
                    ),

                  // Markers Layer
                  MarkerLayer(
                    markers: [
                      // User Current Location Marker
                      Marker(
                        point: _userLocation,
                        width: 90,
                        height: 90,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, _) => _buildUserMarker(),
                        ),
                      ),

                      // Detections & Hazard Pins
                      ...allItems.map((item) {
                        final isSelected = _selectedItem?.id == item.id;
                        final color = AppTheme.getSeverityColor(item.severity);

                        return Marker(
                          point: LatLng(item.latitude, item.longitude),
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedItem = item);
                              _mapController.move(
                                LatLng(item.latitude, item.longitude),
                                _mapController.camera.zoom,
                              );
                              HapticFeedback.lightImpact();
                            },
                            child: _buildItemMarker(item, color, isSelected),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),

              // Top Navigation Bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Circular Back Button
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
                      const SizedBox(width: 12),

                      // Live Map Info & Compass Heading Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (hasHazardInRadius && closestHazard != null) {
                              HapticFeedback.mediumImpact();
                              _mapController.move(
                                LatLng(
                                  closestHazard.latitude,
                                  closestHazard.longitude,
                                ),
                                16.5,
                              );
                              setState(() => _selectedItem = closestHazard);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: hasHazardInRadius
                                    ? alertSeverityColor.withValues(alpha: 0.55)
                                    : AppTheme.borderLight,
                                width: hasHazardInRadius ? 1.5 : 1.2,
                              ),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: hasHazardInRadius
                                        ? alertSeverityColor.withValues(alpha: 0.14)
                                        : AppTheme.accentAmber.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      hasHazardInRadius
                                          ? Icons.warning_amber_rounded
                                          : Icons.radar_rounded,
                                      size: 18,
                                      color: hasHazardInRadius
                                          ? alertSeverityColor
                                          : AppTheme.accentAmber,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        hasHazardInRadius
                                            ? (hazardsInRadius.length == 1
                                                ? '${closestHazard!.damageType} In Range!'
                                                : '${hazardsInRadius.length} Hazards In Range!')
                                            : 'Live Hazard Map',
                                        style: TextStyle(
                                          color: hasHazardInRadius
                                              ? alertSeverityColor
                                              : AppTheme.textPrimary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        hasHazardInRadius
                                            ? '${closestHazard!.distanceMeters.toInt()}m away • ${closestHazard.severity}'
                                            : '${allItems.length} hazards • $userCaptureCount captures',
                                        style: TextStyle(
                                          color: hasHazardInRadius
                                              ? AppTheme.textPrimary.withValues(alpha: 0.8)
                                              : AppTheme.textSecondary,
                                          fontSize: 11,
                                          fontWeight: hasHazardInRadius
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.chipBackground,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.borderLight,
                                      width: 1.0,
                                    ),
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
                                        '${_currentCompassHeading.toInt()}° ${_getHeadingCardinal(_currentCompassHeading)}',
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
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
              ),

              // Floating Controls on the Bottom Right Side
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                right: 16,
                bottom: _selectedItem != null ? 220 : 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Recenter GPS Location Button
                    _buildFloatingButton(
                      icon: Icons.my_location,
                      color: Colors.blueAccent,
                      tooltip: 'My GPS Location',
                      onTap: _recenterGps,
                    ),
                    const SizedBox(height: 10),

                    // Map Style Switcher Button
                    _buildFloatingButton(
                      icon: Icons.layers_outlined,
                      color: AppTheme.textPrimary,
                      tooltip: 'Map Style: ${_mapStyle.toUpperCase()}',
                      onTap: _cycleMapStyle,
                    ),
                  ],
                ),
              ),

              // Selected Detection Detail Card at the Bottom
              if (_selectedItem != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: _buildSelectedItemCard(_selectedItem!),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Center(
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  Widget _buildUserMarker() {
    final angleRad = (_currentCompassHeading - 90.0) * (math.pi / 180.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Directional vision beam
        CustomPaint(
          size: const Size(90, 90),
          painter: HeadingConePainter(
            color: Colors.blueAccent,
            angleRadians: angleRad,
          ),
        ),

        // Pulsing ring
        Container(
          width: 55 * _pulseAnimation.value,
          height: 55 * _pulseAnimation.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.14),
            border: Border.all(
              color: Colors.blue.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
        ),

        // Glow halo
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.3),
          ),
        ),

        // Blue center dot with navigation indicator
        Transform.rotate(
          angle: angleRad + (math.pi / 2.0),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.navigation,
                size: 9.5,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemMarker(MapHazardItem item, Color color, bool isSelected) {
    final severityColor = AppTheme.getSeverityColor(item.severity);
    final pinSize = isSelected ? 34.0 : 28.0;
    final discWidth = isSelected ? 18.0 : 14.0;
    final discHeight = isSelected ? 7.0 : 5.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.location_on_rounded,
              size: pinSize + 2,
              color: Colors.black.withValues(alpha: 0.6),
            ),
            Icon(
              Icons.location_on_rounded,
              size: pinSize,
              color: severityColor,
            ),
            if (item.isUserCapture)
              Positioned(
                top: 10,
                child: Container(
                  width: 6,
                  height: 6,
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
            width: discWidth,
            height: discHeight,
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.all(
                Radius.elliptical(discWidth, discHeight),
              ),
              border: Border.all(
                color: severityColor.withValues(alpha: 0.85),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemCard(MapHazardItem item) {
    final severityColor = AppTheme.getSeverityColor(item.severity);
    final damageColor = AppTheme.getDamageTypeColor(item.damageType);

    final distanceM = ReportRepository.distanceBetween(
      _userLocation.latitude,
      _userLocation.longitude,
      item.latitude,
      item.longitude,
    );

    final hasPhoto =
        item.imagePath != null && File(item.imagePath!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.borderMedium,
          width: 1.2,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasPhoto)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(item.imagePath!),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: damageColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    AppTheme.getDamageTypeIcon(item.damageType),
                    color: damageColor,
                    size: 24,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isUserCapture) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.obsidianBlack,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.address,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedItem = null),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.chipBackground,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: severityColor.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  item.severity.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: damageColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.damageType,
                  style: TextStyle(
                    color: damageColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (item.confidence > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '${(item.confidence * 100).toInt()}% Conf',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                distanceM > 0
                    ? (distanceM >= 1000
                        ? '${(distanceM / 1000).toStringAsFixed(1)}km away'
                        : '${distanceM.toInt()}m away')
                    : 'Nearby',
                style: TextStyle(
                  color: severityColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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
