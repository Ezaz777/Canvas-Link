/// WallpaperSync — Wallpaper Service
/// Handles the full wallpaper sync pipeline for the mobile client.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../utils/settings.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WallpaperService {
  static const MethodChannel _nativeChannel = MethodChannel('com.wallpapersync.app/wallpaper');

  /// Resolves the screen target string ('both', 'home', 'lock').
  static Future<String> _resolveTarget({String? target, int? location}) async {
    if (target != null && (target == 'home' || target == 'lock' || target == 'both')) {
      return target;
    }
    if (location != null) {
      if (location == AsyncWallpaper.HOME_SCREEN) return 'home';
      if (location == AsyncWallpaper.LOCK_SCREEN) return 'lock';
      return 'both';
    }
    return await Settings.getScreenTarget();
  }

  /// Full wallpaper sync pipeline:
  /// 1. Load auth token
  /// 2. Fetch wallpaper URL from backend based on frequency & current hour
  /// 3. Download the image
  /// 4. Set as wallpaper via native WallpaperManager (Home, Lock, or Both based on settings)
  ///
  /// Returns true on success, throws on failure.
  static Future<bool> syncWallpaper({String? target, int? location, int? frequency, int? hour}) async {
    // 1. Get auth token
    final token = await AuthService.getToken();
    if (token == null) {
      throw UnauthorizedException('No auth token found. Please log in again.');
    }

    final freq = frequency ?? await Settings.getSyncFrequency();
    final now = DateTime.now();
    final currentHour = hour ?? now.hour;

    // 2. Fetch wallpaper URL from backend for this interval
    final api = ApiService(token);
    final data = await api.getWallpaper(frequency: freq, hour: currentHour);
    final imageUrl = data['image_url'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      throw ApiException('No wallpaper image found in response.', 404);
    }

    print('WallpaperSync: Got wallpaper URL for pin ${data['pin_id']} (hour: $currentHour, freq: ${freq}h)');

    // 3. Download the image
    final imagePath = await _downloadImage(imageUrl);
    if (imagePath == null) {
      throw ApiException(
          'Failed to download wallpaper image. Please check your internet connection.',
          500);
    }

    // 4. Set as wallpaper (Home, Lock, or Both)
    final resolvedTarget = await _resolveTarget(target: target, location: location);
    final bool result = await _applyToDevice(imagePath, resolvedTarget);
    
    if (!result) {
      throw ApiException(
          'Failed to set wallpaper on device. Check wallpaper permissions.',
          500);
    }

    // Record last sync date and interval key
    if (data['date'] != null) {
      await Settings.setLastSyncDate(data['date'] as String);
    }
    final intervalKey = Settings.getIntervalKey(now, freq);
    await Settings.setLastSyncIntervalKey(intervalKey);

    print('WallpaperSync: Wallpaper applied successfully for interval $intervalKey!');
    return true;
  }

  /// Instantly downloads and applies a specific image as the wallpaper.
  /// Bypasses the daily backend sync logic.
  static Future<bool> setWallpaperFromUrl(String url, {String? target, int? location}) async {
    print('WallpaperSync: Setting manual wallpaper...');
    final imagePath = await _downloadImage(url);
    if (imagePath == null) {
      throw ApiException('Failed to download image from Pinterest.', 500);
    }

    final resolvedTarget = await _resolveTarget(target: target, location: location);
    final bool result = await _applyToDevice(imagePath, resolvedTarget);
    
    if (!result) {
      throw ApiException('Failed to set wallpaper on device.', 500);
    }
    return true;
  }

  /// Applies wallpaper to device natively via WallpaperManager stream, with fallback to plugin.
  static Future<bool> _applyToDevice(String filePath, String target) async {
    // 1. Try native MethodChannel (100% crash-free, stream-based, background thread)
    try {
      final result = await _nativeChannel.invokeMethod('setWallpaper', {
        'filePath': filePath,
        'location': target,
      });
      if (result == true) {
        print('WallpaperSync: Wallpaper set successfully via native channel ($target)');
        return true;
      }
    } catch (e) {
      print('WallpaperSync: Native channel invocation exception: $e. Trying fallback...');
    }

    // 2. Fallback to async_wallpaper plugin
    try {
      int loc;
      if (target == 'home') {
        loc = AsyncWallpaper.HOME_SCREEN;
      } else if (target == 'lock') {
        loc = AsyncWallpaper.LOCK_SCREEN;
      } else {
        loc = AsyncWallpaper.BOTH_SCREENS;
      }

      if (loc == AsyncWallpaper.BOTH_SCREENS) {
        final home = await AsyncWallpaper.setWallpaperFromFile(
          filePath: filePath,
          wallpaperLocation: AsyncWallpaper.HOME_SCREEN,
          goToHome: false,
        ) ?? false;

        await Future.delayed(const Duration(milliseconds: 200));

        final lock = await AsyncWallpaper.setWallpaperFromFile(
          filePath: filePath,
          wallpaperLocation: AsyncWallpaper.LOCK_SCREEN,
          goToHome: false,
        ) ?? false;

        return home || lock;
      } else {
        return await AsyncWallpaper.setWallpaperFromFile(
          filePath: filePath,
          wallpaperLocation: loc,
          goToHome: false,
        ) ?? false;
      }
    } catch (err) {
      print('WallpaperSync: Fallback plugin also failed: $err');
      throw ApiException('Error applying wallpaper: $err', 500);
    }
  }

  /// Download an image from URL to a temporary file with retry fallbacks.
  static Future<String?> _downloadImage(String url) async {
    final candidateUrls = <String>[url];

    // Build fallback URLs for Pinterest CDN variants
    if (url.contains('/originals/')) {
      candidateUrls.add(url.replaceAll('/originals/', '/1200x/'));
      candidateUrls.add(url.replaceAll('/originals/', '/736x/'));
      candidateUrls.add(url.replaceAll('/originals/', '/600x/'));
    } else if (url.contains('/1200x/')) {
      candidateUrls.add(url.replaceAll('/1200x/', '/736x/'));
      candidateUrls.add(url.replaceAll('/1200x/', '/600x/'));
    }

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
    };

    for (final candidate in candidateUrls) {
      try {
        final response = await http.get(Uri.parse(candidate), headers: headers);
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final tempDir = await getTemporaryDirectory();
          
          // Clean up old cached wallpapers to save space
          try {
            final files = tempDir.listSync();
            for (var file in files) {
              if (file.path.contains('wallpaper_')) {
                file.deleteSync();
              }
            }
          } catch (_) {}

          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final filePath = '${tempDir.path}/wallpaper_download_$timestamp.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          return filePath;
        }
      } catch (e) {
        print('WallpaperSync: Download attempt failed for $candidate: $e');
      }
    }

    return null;
  }
}
