/// WallpaperSync — Background Worker
/// Headless background task that syncs wallpaper via WorkManager.

import 'package:workmanager/workmanager.dart';
import '../services/wallpaper_service.dart';
import '../utils/settings.dart';

/// Unique task name for WorkManager registration.
const String wallpaperSyncTaskName = 'com.wallpapersync.dailySync';
const String wallpaperSyncTaskTag = 'wallpaper_sync_daily';

/// Top-level callback dispatcher for WorkManager.
/// This MUST be a top-level function (not inside a class).
/// The @pragma ensures it's not stripped during tree-shaking in release builds.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    print('WallpaperSync Worker: Task "$taskName" started.');

    try {
      final hours = await Settings.getSyncFrequency();
      if (hours == 0) {
        print('WallpaperSync Worker: Sync frequency is Off. Skipping.');
        return true;
      }

      // Check if current interval has already been applied (e.g. by manual selection or recent sync)
      final now = DateTime.now();
      final currentIntervalKey = Settings.getIntervalKey(now, hours);
      final lastInterval = await Settings.getLastSyncIntervalKey();

      if (lastInterval == currentIntervalKey) {
        print('WallpaperSync Worker: Interval $currentIntervalKey already synced. Skipping to preserve wallpaper.');
        return true;
      }

      final success = await WallpaperService.syncWallpaper(frequency: hours, hour: now.hour);
      print('WallpaperSync Worker: Task completed. Success: $success');
      return success;
    } catch (e) {
      print('WallpaperSync Worker: Task failed with error: $e');
      return Future.value(false);
    }
  });
}

/// Helper class to manage WorkManager scheduling.
class WallpaperWorker {
  /// Initialize WorkManager with the callback dispatcher.
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );
  }

  /// Register a periodic background task based on the user's saved settings.
  /// Uses ExistingWorkPolicy.keep to prevent immediate execution on every app launch.
  /// Set forceUpdate = true when user explicitly modifies settings.
  static Future<void> registerPeriodicSync({bool forceUpdate = false}) async {
    final hours = await Settings.getSyncFrequency();
    
    if (hours == 0) {
      await cancelAll();
      print('WallpaperSync: Sync frequency is Off. Task cancelled.');
      return;
    }

    if (forceUpdate) {
      await cancelAll();
    }

    Duration initialDelay = Duration.zero;
    if (hours == 24) {
      final dailyTime = await Settings.getDailySyncTime();
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, dailyTime.hour, dailyTime.minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      initialDelay = scheduled.difference(now);
      print('WallpaperSync: Daily sync scheduled for ${dailyTime.hour}:${dailyTime.minute.toString().padLeft(2, '0')} (initial delay: ${initialDelay.inMinutes}m).');
    }

    // Register periodic sync without restrictive battery gates that prevent Android background execution
    await Workmanager().registerPeriodicTask(
      wallpaperSyncTaskTag,
      wallpaperSyncTaskName,
      frequency: Duration(hours: hours),
      initialDelay: initialDelay,
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
      existingWorkPolicy: forceUpdate ? ExistingWorkPolicy.replace : ExistingWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
    print('WallpaperSync: Periodic sync task registered (every ${hours}h, forceUpdate: $forceUpdate).');
  }

  /// Run the sync task once immediately.
  static Future<void> runOnce() async {
    await Workmanager().registerOneOffTask(
      '${wallpaperSyncTaskTag}_once',
      wallpaperSyncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    print('WallpaperSync: One-time sync task registered.');
  }

  /// Cancel all scheduled sync tasks.
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('WallpaperSync: All sync tasks cancelled.');
  }
}
