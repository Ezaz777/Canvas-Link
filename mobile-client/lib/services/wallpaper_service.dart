/// WallpaperSync — Wallpaper Service
/// Handles the full wallpaper sync pipeline for the mobile client.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../utils/image_utils.dart';
import '../utils/settings.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WallpaperService {
  /// Resolves the AsyncWallpaper target from user settings or direct override.
  static Future<int> _resolveWallpaperLocation([int? location]) async {
    if (location != null) return location;
    final target = await Settings.getScreenTarget();
    switch (target) {
      case 'home':
        return AsyncWallpaper.HOME_SCREEN;
      case 'lock':
        return AsyncWallpaper.LOCK_SCREEN;
      case 'both':
      default:
        return AsyncWallpaper.BOTH_SCREENS;
    }
  }

  /// Full wallpaper sync pipeline:
  /// 1. Load auth token
  /// 2. Fetch today's wallpaper URL from backend
  /// 3. Download the image
  /// 4. Center-crop to device screen dimensions
  /// 5. Set as wallpaper (Home, Lock, or Both based on settings)
  ///
  /// Returns true on success, throws on failure.
  static Future<bool> syncWallpaper({int? location}) async {
    // 1. Get auth token
    final token = await AuthService.getToken();
    if (token == null) {
      throw UnauthorizedException('No auth token found. Please log in again.');
    }

    // 2. Fetch wallpaper URL from backend
    final api = ApiService(token);
    final data = await api.getWallpaper();
    final imageUrl = data['image_url'] as String?;

    if (imageUrl == null || imageUrl.isEmpty) {
      throw ApiException('No wallpaper image found in response.', 404);
    }

    print('WallpaperSync: Got wallpaper URL for pin ${data['pin_id']}');

    // 3. Download the image
    final imagePath = await _downloadImage(imageUrl);
    if (imagePath == null) {
      throw ApiException(
          'Failed to download wallpaper image. Please check your internet connection.',
          500);
    }

    // 4. Get screen dimensions and center-crop
    final screenRes = ImageUtils.getScreenResolution();
    final croppedPath = await ImageUtils.centerCrop(
      imagePath,
      screenRes['width']!,
      screenRes['height']!,
    );

    print('WallpaperSync: Image cropped to ${screenRes['width']}x${screenRes['height']}');

    // 5. Set as wallpaper (Home, Lock, or Both)
    final wallpaperLocation = await _resolveWallpaperLocation(location);
    final bool result = await _applyToDevice(croppedPath, wallpaperLocation);
    
    if (!result) {
      throw ApiException(
          'Failed to set wallpaper on device. Check wallpaper permissions.',
          500);
    }

    print('WallpaperSync: Wallpaper applied successfully!');
    return true;
  }

  /// Instantly downloads and applies a specific image as the wallpaper.
  /// Bypasses the daily backend sync logic.
  static Future<bool> setWallpaperFromUrl(String url, {int? location}) async {
    print('WallpaperSync: Setting manual wallpaper...');
    final imagePath = await _downloadImage(url);
    if (imagePath == null) {
      throw ApiException('Failed to download image from Pinterest.', 500);
    }

    final screenRes = ImageUtils.getScreenResolution();
    final croppedPath = await ImageUtils.centerCrop(
      imagePath,
      screenRes['width']!,
      screenRes['height']!,
    );

    final wallpaperLocation = await _resolveWallpaperLocation(location);
    final bool result = await _applyToDevice(croppedPath, wallpaperLocation);
    
    if (!result) {
      throw ApiException('Failed to set wallpaper on device.', 500);
    }
    return true;
  }

  /// Applies wallpaper to device, handling OEM-specific restrictions on lock screen.
  static Future<bool> _applyToDevice(String croppedPath, int wallpaperLocation) async {
    try {
      if (wallpaperLocation == AsyncWallpaper.BOTH_SCREENS) {
        // Many Android OEM skins (Xiaomi HyperOS/MIUI, Samsung OneUI, ColorOS)
        // ignore FLAG_LOCK when set concurrently with BOTH_SCREENS.
        // Applying sequentially ensures both screens receive the update.
        final homeResult = await AsyncWallpaper.setWallpaperFromFile(
          filePath: croppedPath,
          wallpaperLocation: AsyncWallpaper.HOME_SCREEN,
          goToHome: false,
        ) ?? false;

        await Future.delayed(const Duration(milliseconds: 250));

        final lockResult = await AsyncWallpaper.setWallpaperFromFile(
          filePath: croppedPath,
          wallpaperLocation: AsyncWallpaper.LOCK_SCREEN,
          goToHome: false,
        ) ?? false;

        return homeResult || lockResult;
      } else {
        return await AsyncWallpaper.setWallpaperFromFile(
          filePath: croppedPath,
          wallpaperLocation: wallpaperLocation,
          goToHome: false,
        ) ?? false;
      }
    } catch (e) {
      print('WallpaperSync: Native error applying wallpaper: $e');
      throw ApiException('Error applying wallpaper: $e', 500);
    }
  }

  /// Download an image from URL to a temporary file.
  static Future<String?> _downloadImage(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        return null;
      }

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
    } catch (e) {
      print('WallpaperSync: Download error - $e');
      return null;
    }
  }
}
