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
      final success = await WallpaperService.syncWallpaper();
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
  /// Requires network connectivity.
  static Future<void> registerPeriodicSync() async {
    final hours = await Settings.getSyncFrequency();
    
    if (hours == 0) {
      await cancelAll();
      print('WallpaperSync: Sync frequency is Off. Task cancelled.');
      return;
    }

    // Cancel old tasks to replace them cleanly. WorkManager's replace policy 
    // sometimes behaves unexpectedly if the frequency changes significantly.
    await cancelAll();

    await Workmanager().registerPeriodicTask(
      wallpaperSyncTaskTag,
      wallpaperSyncTaskName,
      frequency: Duration(hours: hours),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
    print('WallpaperSync: Periodic sync task registered (every ${hours}h).');
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
