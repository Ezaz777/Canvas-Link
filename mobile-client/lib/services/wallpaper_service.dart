/// WallpaperSync — Wallpaper Service
/// Handles the full wallpaper sync pipeline for the mobile client.

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_plus/wallpaper_manager_plus.dart';
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
    try {
      // 1. Get auth token
      final token = await AuthService.getToken();
      if (token == null) {
        print('WallpaperSync: No auth token found. User not logged in.');
        return false;
      }

      // 2. Fetch wallpaper URL from backend
      final api = ApiService(token);
      final data = await api.getWallpaper();
      final imageUrl = data['image_url'] as String?;

      if (imageUrl == null || imageUrl.isEmpty) {
        print('WallpaperSync: No image URL received from backend.');
        return false;
      }

      print('WallpaperSync: Got wallpaper URL for pin ${data['pin_id']}');

      // 3. Download the image
      final imagePath = await _downloadImage(imageUrl);
      if (imagePath == null) {
        print('WallpaperSync: Failed to download image.');
        return false;
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
      await WallpaperManagerPlus().setWallpaper(
        File(croppedPath),
        WallpaperManagerPlus.bothScreens,
      );

      print('WallpaperSync: Wallpaper applied successfully!');
      return true;
    } on PaymentRequiredException {
      print('WallpaperSync: Subscription not active. Skipping.');
      return false;
    } on UnauthorizedException {
      print('WallpaperSync: Auth token expired.');
      return false;
    } catch (e) {
      print('WallpaperSync: Error during sync - $e');
      return false;
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
      final filePath = '${tempDir.path}/wallpaper_download.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      return filePath;
    } catch (e) {
      print('WallpaperSync: Download error - $e');
      return null;
    }
  }
}
