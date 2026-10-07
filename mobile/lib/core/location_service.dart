import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Service managing device GPS location and coordinate distance calculations.
class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Default focal coordinate (Dhaka Center, aligned with sample data)
  static const LatLng defaultLocation = LatLng(23.8103, 90.4125);

  LatLng _lastKnownLocation = defaultLocation;
  LatLng get lastKnownLocation => _lastKnownLocation;
  bool _hasRealGpsFix = false;
  bool get hasRealGpsFix => _hasRealGpsFix;

  /// Fetch current GPS position with permission negotiation and fast fallback
  Future<LatLng> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _lastKnownLocation;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _lastKnownLocation;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return _lastKnownLocation;
      }

      // Check last known location first for instantaneous resolution
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _lastKnownLocation = LatLng(lastPos.latitude, lastPos.longitude);
        _hasRealGpsFix = true;
      }

      // Try high-accuracy GPS fix first
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
        _lastKnownLocation = LatLng(position.latitude, position.longitude);
        _hasRealGpsFix = true;
        return _lastKnownLocation;
      } catch (_) {
        // High accuracy timed out (common indoors or emulator); fallback to medium/balanced
        try {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
          _lastKnownLocation = LatLng(position.latitude, position.longitude);
          _hasRealGpsFix = true;
          return _lastKnownLocation;
        } catch (_) {
          return _lastKnownLocation;
        }
      }
    } catch (_) {
      try {
        final lastPos = await Geolocator.getLastKnownPosition();
        if (lastPos != null) {
          _lastKnownLocation = LatLng(lastPos.latitude, lastPos.longitude);
          _hasRealGpsFix = true;
        }
      } catch (_) {}
      return _lastKnownLocation;
    }
  }

  /// Calculates geodesic distance between two points in meters
  double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// Optional position stream for live movement tracking
  Stream<Position>? getPositionStream() {
    try {
      return Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
