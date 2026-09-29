/// WallpaperSync — Wallpaper Service
/// Handles the full wallpaper sync pipeline for the mobile client.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import '../utils/image_utils.dart';
import 'api_service.dart';
import 'auth_service.dart';

class WallpaperService {
  /// Full wallpaper sync pipeline:
  /// 1. Load auth token
  /// 2. Fetch today's wallpaper URL from backend
  /// 3. Download the image
  /// 4. Center-crop to device screen dimensions
  /// 5. Set as Home + Lock screen wallpaper
  ///
  /// Returns true on success, false on failure.
  static Future<bool> syncWallpaper() async {
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

    // 5. Set as wallpaper (both Home and Lock screen)
    final bool result = await AsyncWallpaper.setWallpaperFromFile(
      filePath: croppedPath,
      wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
      goToHome: false,
    ) ?? false;
    
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
  static Future<bool> setWallpaperFromUrl(String url) async {
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

    final bool result = await AsyncWallpaper.setWallpaperFromFile(
      filePath: croppedPath,
      wallpaperLocation: AsyncWallpaper.BOTH_SCREENS,
      goToHome: false,
    ) ?? false;
    
    if (!result) {
      throw ApiException('Failed to set wallpaper on device.', 500);
    }
    return true;
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
