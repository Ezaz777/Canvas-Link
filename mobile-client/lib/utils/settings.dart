import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Settings {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
  );
  static const String _syncFrequencyKey = 'sync_frequency';
  static const String _screenTargetKey = 'wallpaper_screen_target';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _screenWidthKey = 'device_screen_width';
  static const String _screenHeightKey = 'device_screen_height';
  static const String _lastSyncDateKey = 'last_sync_date';
  static const String _dailySyncTimeKey = 'daily_sync_time';
  static const String _isProKey = 'is_canvas_link_pro';

  // Frequencies in hours. 0 means Off.
  static const List<int> availableFrequencies = [0, 1, 6, 12, 24];

  // Screen targets: 'both', 'home', 'lock'
  static const List<String> availableTargets = ['both', 'home', 'lock'];
  static const List<String> availableScreenTargets = availableTargets;

  // Theme modes: 'system', 'light', 'dark'
  static const List<String> availableThemeModes = ['system', 'light', 'dark'];

  /// Cache device physical screen dimensions so background workers know exact resolution.
  static Future<void> saveScreenDimensions(int width, int height) async {
    if (width > 0 && height > 0) {
      try {
        await _storage.write(key: _screenWidthKey, value: width.toString());
        await _storage.write(key: _screenHeightKey, value: height.toString());
      } catch (_) {}
    }
  }

  /// Retrieve cached physical screen dimensions.
  static Future<Map<String, int>?> getSavedScreenDimensions() async {
    try {
      final wStr = await _storage.read(key: _screenWidthKey);
      final hStr = await _storage.read(key: _screenHeightKey);
      if (wStr != null && hStr != null) {
        final w = int.tryParse(wStr);
        final h = int.tryParse(hStr);
        if (w != null && h != null && w > 0 && h > 0) {
          return {'width': w, 'height': h};
        }
      }
    } catch (_) {}
    return null;
  }

  /// Get the date string (YYYY-MM-DD) of the last successful wallpaper sync.
  static Future<String?> getLastSyncDate() async {
    try {
      return await _storage.read(key: _lastSyncDateKey);
    } catch (_) {
      return null;
    }
  }

  /// Record the date of the last successful wallpaper sync.
  static Future<void> setLastSyncDate(String date) async {
    try {
      await _storage.write(key: _lastSyncDateKey, value: date);
    } catch (_) {}
  }

  /// Get the interval key (e.g. 2026-10-01_int0) of the last successful wallpaper sync.
  static Future<String?> getLastSyncIntervalKey() async {
    try {
      return await _storage.read(key: 'last_sync_interval_key');
    } catch (_) {
      return null;
    }
  }

  /// Record the interval key of the last successful wallpaper sync.
  static Future<void> setLastSyncIntervalKey(String key) async {
    try {
      await _storage.write(key: 'last_sync_interval_key', value: key);
    } catch (_) {}
  }

  /// Get the pin ID of the currently active wallpaper set on this device.
  static Future<String?> getActivePinId() async {
    try {
      return await _storage.read(key: 'active_wallpaper_pin_id');
    } catch (_) {
      return null;
    }
  }

  /// Record the pin ID of the currently active wallpaper.
  static Future<void> setActivePinId(String pinId) async {
    try {
      await _storage.write(key: 'active_wallpaper_pin_id', value: pinId);
    } catch (_) {}
  }

  /// Get the image URL of the currently active wallpaper set on this device.
  static Future<String?> getActiveImageUrl() async {
    try {
      return await _storage.read(key: 'active_wallpaper_image_url');
    } catch (_) {
      return null;
    }
  }

  /// Record the image URL of the currently active wallpaper.
  static Future<void> setActiveImageUrl(String url) async {
    try {
      await _storage.write(key: 'active_wallpaper_image_url', value: url);
    } catch (_) {}
  }

  /// Get the configured favorite time for daily wallpaper change (defaults to 8:00 AM).
  static Future<TimeOfDay> getDailySyncTime() async {
    try {
      final value = await _storage.read(key: _dailySyncTimeKey);
      if (value != null && value.contains(':')) {
        final parts = value.split(':');
        final h = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        if (h != null && m != null && h >= 0 && h < 24 && m >= 0 && m < 60) {
          return TimeOfDay(hour: h, minute: m);
        }
      }
    } catch (_) {}
    return const TimeOfDay(hour: 8, minute: 0);
  }

  /// Save the configured favorite time for daily wallpaper change.
  static Future<void> setDailySyncTime(int hour, int minute) async {
    try {
      final formatted = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      await _storage.write(key: _dailySyncTimeKey, value: formatted);
    } catch (_) {}
  }

  /// Format hour and minute into a readable display string like "8:00 AM" or "10:30 PM".
  static String formatTimeOfDayDisplay(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  /// Get the configured sync frequency in hours. Defaults to 24.
  static Future<int> getSyncFrequency() async {
    try {
      final value = await _storage.read(key: _syncFrequencyKey);
      if (value != null) {
        final parsed = int.tryParse(value);
        if (parsed != null && availableFrequencies.contains(parsed)) {
          return parsed;
        }
      }
    } catch (e) {
      print('Settings: Error reading sync frequency: $e');
    }
    return 24; // Default to Daily
  }

  /// Save the configured sync frequency in hours.
  static Future<void> setSyncFrequency(int hours) async {
    if (availableFrequencies.contains(hours)) {
      try {
        await _storage.write(key: _syncFrequencyKey, value: hours.toString());
      } catch (e) {
        print('Settings: Error writing sync frequency: $e');
      }
    }
  }

  /// Get the configured wallpaper screen target ('both', 'home', 'lock'). Defaults to 'both'.
  static Future<String> getScreenTarget() async {
    try {
      final value = await _storage.read(key: _screenTargetKey);
      if (value != null && availableTargets.contains(value)) {
        return value;
      }
    } catch (_) {}
    return 'both';
  }

  /// Save the configured wallpaper screen target ('both', 'home', 'lock').
  static Future<void> setScreenTarget(String target) async {
    if (availableTargets.contains(target)) {
      try {
        await _storage.write(key: _screenTargetKey, value: target);
      } catch (_) {}
    }
  }

  /// Get the configured theme mode ('system', 'light', 'dark'). Defaults to 'system'.
  static Future<String> getThemeMode() async {
    try {
      final value = await _storage.read(key: _themeModeKey);
      if (value != null && availableThemeModes.contains(value)) {
        return value;
      }
    } catch (_) {}
    return 'system';
  }

  /// Save the configured theme mode ('system', 'light', 'dark').
  static Future<void> setThemeMode(String mode) async {
    if (availableThemeModes.contains(mode)) {
      try {
        await _storage.write(key: _themeModeKey, value: mode);
      } catch (_) {}
    }
  }

  /// Convert theme mode to display string
  static String getThemeModeDisplayString(String mode) {
    switch (mode) {
      case 'light':
        return 'Light Mode';
      case 'dark':
        return 'Dark Mode';
      case 'system':
      default:
        return 'System Default';
    }
  }

  /// Generate a deterministic interval key based on date and frequency (matches backend formula)
  static String getIntervalKey(DateTime now, int frequency) {
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final freq = (frequency > 0 && frequency <= 24) ? frequency : 24;
    final intervalIndex = now.hour ~/ freq;
    return '${dateStr}_int$intervalIndex';
  }

  /// Convert frequency hours to a display string.
  static String getFrequencyDisplayString(int hours, {TimeOfDay? dailyTime}) {
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
        if (dailyTime != null) {
          return 'Daily at ${formatTimeOfDayDisplay(dailyTime.hour, dailyTime.minute)}';
        }
        return 'Daily wallpaper change';
      default:
        return 'Every ${hours}h';
    }
  }

  /// Compact frequency string for badges and dashboard stats.
  static String getFrequencyShortString(int hours, {TimeOfDay? dailyTime}) {
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
        if (dailyTime != null) {
          return 'Daily (${formatTimeOfDayDisplay(dailyTime.hour, dailyTime.minute)})';
        }
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

  /// Check whether user has unlocked Pinterest Auto Wallpaper Pro
  static Future<bool> isPro() async {
    try {
      final val = await _storage.read(key: _isProKey);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Update local Pro status
  static Future<void> setPro(bool isPro) async {
    try {
      await _storage.write(key: _isProKey, value: isPro.toString());
    } catch (_) {}
  }

  /// Whether a specific sync frequency requires Pro
  static bool isFrequencyProOnly(int hours) {
    return hours == 1 || hours == 6;
  }

  /// Whether a specific screen target requires Pro
  static bool isScreenTargetProOnly(String target) {
    return target == 'both' || target == 'lock';
  }
}
