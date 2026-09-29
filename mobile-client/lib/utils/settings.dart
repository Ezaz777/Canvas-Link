import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings {
  static const _storage = FlutterSecureStorage();
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _screenTargetKey = 'wallpaper_screen_target';

  // Frequencies in hours. 0 means Off.
  static const List<int> availableFrequencies = [0, 1, 6, 12, 24];

  // Screen targets: 'both', 'home', 'lock'
  static const List<String> availableTargets = ['both', 'home', 'lock'];
  static const List<String> availableScreenTargets = availableTargets;

  /// Get the configured sync frequency in hours. Defaults to 24.
  static Future<int> getSyncFrequency() async {
    final value = await _storage.read(key: _syncFrequencyKey);
    if (value != null) {
      final parsed = int.tryParse(value);
      if (parsed != null && availableFrequencies.contains(parsed)) {
        return parsed;
      }
    }
    return 24; // Default to Daily
  }

  /// Save the configured sync frequency in hours.
  static Future<void> setSyncFrequency(int hours) async {
    if (availableFrequencies.contains(hours)) {
      await _storage.write(key: _syncFrequencyKey, value: hours.toString());
    }
  }

  /// Get the configured wallpaper screen target ('both', 'home', 'lock'). Defaults to 'both'.
  static Future<String> getScreenTarget() async {
    final value = await _storage.read(key: _screenTargetKey);
    if (value != null && availableTargets.contains(value)) {
      return value;
    }
    return 'both';
  }

  /// Save the configured wallpaper screen target ('both', 'home', 'lock').
  static Future<void> setScreenTarget(String target) async {
    if (availableTargets.contains(target)) {
      await _storage.write(key: _screenTargetKey, value: target);
    }
  }

  /// Convert frequency hours to a display string.
  static String getFrequencyDisplayString(int hours) {
    switch (hours) {
      case 0:
        return 'Off';
      case 1:
        return '1 Hour';
      case 6:
        return '6 Hours';
      case 12:
        return '12 Hours';
      case 24:
        return 'Daily (24h)';
      default:
        return '${hours}h';
    }
  }

  /// Convert screen target to a display string.
  static String getScreenTargetDisplayString(String target) {
    switch (target) {
      case 'home':
        return 'Home Screen Only';
      case 'lock':
        return 'Lock Screen Only';
      case 'both':
      default:
        return 'Home & Lock Screens';
    }
  }
}
