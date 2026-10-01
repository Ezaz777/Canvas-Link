import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings {
  static const _storage = FlutterSecureStorage();
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _screenTargetKey = 'wallpaper_screen_target';
  static const String _screenWidthKey = 'device_screen_width';
  static const String _screenHeightKey = 'device_screen_height';
  static const String _lastSyncDateKey = 'last_sync_date';

  // Frequencies in hours. 0 means Off.
  static const List<int> availableFrequencies = [0, 1, 6, 12, 24];

  // Screen targets: 'both', 'home', 'lock'
  static const List<String> availableTargets = ['both', 'home', 'lock'];
  static const List<String> availableScreenTargets = availableTargets;

  /// Cache device physical screen dimensions so background workers know exact resolution.
  static Future<void> saveScreenDimensions(int width, int height) async {
    if (width > 0 && height > 0) {
      await _storage.write(key: _screenWidthKey, value: width.toString());
      await _storage.write(key: _screenHeightKey, value: height.toString());
    }
  }

  /// Retrieve cached physical screen dimensions.
  static Future<Map<String, int>?> getSavedScreenDimensions() async {
    final wStr = await _storage.read(key: _screenWidthKey);
    final hStr = await _storage.read(key: _screenHeightKey);
    if (wStr != null && hStr != null) {
      final w = int.tryParse(wStr);
      final h = int.tryParse(hStr);
      if (w != null && h != null && w > 0 && h > 0) {
        return {'width': w, 'height': h};
      }
    }
    return null;
  }

  /// Get the date string (YYYY-MM-DD) of the last successful wallpaper sync.
  static Future<String?> getLastSyncDate() async {
    return await _storage.read(key: _lastSyncDateKey);
  }

  /// Record the date of the last successful wallpaper sync.
  static Future<void> setLastSyncDate(String date) async {
    await _storage.write(key: _lastSyncDateKey, value: date);
  }

  /// Get the interval key (e.g. 2026-10-01_h13) of the last successful wallpaper sync.
  static Future<String?> getLastSyncIntervalKey() async {
    return await _storage.read(key: 'last_sync_interval_key');
  }

  /// Record the interval key of the last successful wallpaper sync.
  static Future<void> setLastSyncIntervalKey(String key) async {
    await _storage.write(key: 'last_sync_interval_key', value: key);
  }

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

  /// Generate a deterministic interval key based on date and frequency
  static String getIntervalKey(DateTime now, int frequency) {
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (frequency <= 1) {
      return '${dateStr}_h${now.hour}';
    } else if (frequency == 6) {
      return '${dateStr}_b${now.hour ~/ 6}';
    } else if (frequency == 12) {
      return '${dateStr}_b${now.hour ~/ 12}';
    } else {
      return dateStr;
    }
  }

  /// Convert frequency hours to a display string.
  static String getFrequencyDisplayString(int hours) {
    switch (hours) {
      case 0:
        return 'Off';
      case 1:
        return 'Every 1 Hour';
      case 6:
        return 'Every 6 Hours';
      case 12:
        return 'Every 12 Hours';
      case 24:
        return 'Daily wallpaper change';
      default:
        return 'Every ${hours}h';
    }
  }

  /// Compact frequency string for badges and dashboard stats.
  static String getFrequencyShortString(int hours) {
    switch (hours) {
      case 0:
        return 'Off';
      case 1:
        return 'Every 1h';
      case 6:
        return 'Every 6h';
      case 12:
        return 'Every 12h';
      case 24:
        return 'Daily';
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
