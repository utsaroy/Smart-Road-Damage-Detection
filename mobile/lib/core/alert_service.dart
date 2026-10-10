import 'package:flutter/services.dart';

/// Service for triggering audible proximity alerts, haptic vibrations, and system push notifications.
class AlertService {
  static const MethodChannel _channel = MethodChannel(
    'com.example.amar_path/alert',
  );

  /// Trigger audio, vibration, and/or system push notification.
  static Future<void> triggerAlert({
    bool sound = true,
    bool vibrate = true,
    bool notification = true,
    String title = 'Road Hazard Alert',
    String message = 'Approaching road damage in your scan radius.',
  }) async {
    try {
      await _channel.invokeMethod('playAlert', {
        'sound': sound,
        'vibrate': vibrate,
        'notification': notification,
        'title': title,
        'message': message,
      });
    } catch (_) {
      // Graceful fallback for non-Android platforms, emulator or unit tests
      if (vibrate) {
        await HapticFeedback.heavyImpact();
      }
      if (sound) {
        await SystemSound.play(SystemSoundType.alert);
      }
    }
  }
}
