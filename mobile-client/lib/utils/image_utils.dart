/// WallpaperSync — Image Utilities
/// Center-crop images to match device screen dimensions.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'settings.dart';

class ImageUtils {
  /// Center-crop an image to match the device's screen aspect ratio.
  ///
  /// This prevents horizontal squishing on mobile by cropping the image
  /// to the device's vertical aspect ratio before applying as wallpaper.
  ///
  /// [imagePath] — Path to the downloaded image file
  /// [screenWidth] — Device screen width in pixels
  /// [screenHeight] — Device screen height in pixels
  ///
  /// Returns the path to the cropped image file.
  static Future<String> centerCrop(
    String imagePath,
    int screenWidth,
    int screenHeight,
  ) async {
    // Read the image file
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image: $imagePath');
    }

    // Safety checks for valid dimensions to prevent division by zero in headless worker
    final int targetWidth = screenWidth > 200 ? screenWidth : 1080;
    final int targetHeight = screenHeight > 200 ? screenHeight : 2400;

    int imgWidth = image.width;
    int imgHeight = image.height;
    
    bool isSourceLandscape = imgWidth > imgHeight;
    bool isTargetLandscape = targetWidth > targetHeight;
    
    img.Image currentImage = image;
    
    // Auto-rotate if orientations don't match (e.g. landscape image on portrait phone)
    if (isSourceLandscape != isTargetLandscape) {
      print('ImageUtils: Orientation mismatch. Rotating image 90 degrees.');
      currentImage = img.copyRotate(currentImage, angle: 90);
      imgWidth = currentImage.width;
      imgHeight = currentImage.height;
    }

    final targetRatio = targetWidth / targetHeight;
    final imgRatio = imgWidth / imgHeight;

    int cropX, cropY, cropWidth, cropHeight;

    if (imgRatio > targetRatio) {
      // Image is wider than target — crop horizontally (keep height)
      cropHeight = imgHeight;
      cropWidth = (imgHeight * targetRatio).round();
      cropX = ((imgWidth - cropWidth) / 2).round();
      cropY = 0;
    } else {
      // Image is taller than target — crop vertically (keep width)
      cropWidth = imgWidth;
      cropHeight = (imgWidth / targetRatio).round();
      cropX = 0;
      cropY = ((imgHeight - cropHeight) / 2).round();
    }

    // Perform the center crop
    final cropped = img.copyCrop(
      currentImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to exact screen dimensions for optimal quality
    final resized = img.copyResize(
      cropped,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.linear,
    );

    // Save the cropped image
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${tempDir.path}/wallpaper_cropped_$timestamp.jpg';
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(img.encodeJpg(resized, quality: 95));

    return outputPath;
  }

  /// Get the device's physical screen resolution.
  /// Uses FlutterView when running in foreground, or falls back to
  /// cached dimensions from Settings (crucial for headless background workers).
  static Future<Map<String, int>> getScreenResolution() async {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view != null && view.physicalSize.width > 200 && view.physicalSize.height > 200) {
      final width = view.physicalSize.width.round();
      final height = view.physicalSize.height.round();
      // Cache for background WorkManager isolate
      await Settings.saveScreenDimensions(width, height);
      return {
        'width': width,
        'height': height,
      };
    }

    // Check cached settings from foreground session
    final saved = await Settings.getSavedScreenDimensions();
    if (saved != null && saved['width']! > 200 && saved['height']! > 200) {
      return saved;
    }

    // Fallback for modern Android resolution
    return {'width': 1080, 'height': 2400};
  }
}
