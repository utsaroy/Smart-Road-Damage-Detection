import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Centralized service managing phone hardware compass sensor events,
/// adaptive low-pass smoothing, deadband filtering, and GPS course heading fallback.
class CompassService extends ChangeNotifier {
  static final CompassService instance = CompassService._internal();
  CompassService._internal();

  StreamSubscription<CompassEvent>? _compassSub;
  final StreamController<double> _headingStreamController =
      StreamController<double>.broadcast();

  double _currentHeading = 0.0;
  bool _hasCompassSensor = false;
  bool _isListening = false;

  /// Smoothed real-time heading angle in degrees (0.0 .. 359.9)
  double get currentHeading => _currentHeading;

  /// Whether a physical magnetometer compass sensor is detected on device
  bool get hasCompassSensor => _hasCompassSensor;

  /// Broadcast stream of smoothed heading updates
  Stream<double> get headingStream => _headingStreamController.stream;

  /// Cardinal heading abbreviation (e.g. 'N', 'NE', 'E', 'SE', 'S', etc.)
  String get cardinalDirection => getHeadingCardinal(_currentHeading);

  /// Calculate cardinal direction abbreviation from degrees
  static String getHeadingCardinal(double deg) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((deg + 22.5) % 360 / 45).floor();
    return directions[index % 8];
  }

  /// Start listening to device compass sensor events
  void start() {
    if (_isListening) return;
    _isListening = true;

    try {
      _compassSub = FlutterCompass.events?.listen(
        (event) {
          final heading = event.heading;
          if (heading != null && heading.isFinite) {
            _onCompassUpdate(heading);
          }
        },
        onError: (err) {
          debugPrint('CompassService sensor error: $err');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('CompassService initialization error: $e');
    }
  }

  /// Stop listening to device compass sensor
  void stop() {
    _compassSub?.cancel();
    _compassSub = null;
    _isListening = false;
  }

  /// Process raw sensor reading with adaptive deadband and low-pass filter
  void _onCompassUpdate(double rawHeading) {
    _hasCompassSensor = true;
    final normalized = (rawHeading % 360.0 + 360.0) % 360.0;

    // Calculate shortest angular difference between reading and current smoothed heading
    final diff = _calcShortestAngleDiff(normalized, _currentHeading);
    final absDiff = diff.abs();

    // Deadband threshold: filter out micro-sensor noise below 0.4° to prevent jitter when holding still
    if (absDiff < 0.4) return;

    // Adaptive low-pass filter: fast response when turning, silky smooth when steady
    final factor = absDiff > 25.0 ? 0.60 : (absDiff > 10.0 ? 0.35 : 0.22);
    _currentHeading = (_currentHeading + diff * factor) % 360.0;
    if (_currentHeading < 0) _currentHeading += 360.0;

    _headingStreamController.add(_currentHeading);
    notifyListeners();
  }

  /// Use GPS course heading as complementary source if compass hardware is unavailable or in vehicle
  void updateFromGpsCourse(double gpsHeading, double speedMps) {
    if (!_hasCompassSensor && gpsHeading >= 0 && speedMps > 0.5) {
      _onCompassUpdate(gpsHeading);
    }
  }

  /// Shortest angle difference in range [-180, 180]
  double _calcShortestAngleDiff(double target, double current) {
    double diff = (target - current + 180.0) % 360.0 - 180.0;
    return diff < -180.0 ? diff + 360.0 : diff;
  }

  @override
  void dispose() {
    stop();
    _headingStreamController.close();
    super.dispose();
  }
}
