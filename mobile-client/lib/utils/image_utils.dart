/// WallpaperSync — Image Utilities
/// Center-crop images to match device screen dimensions.

import 'dart:io';
import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

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

    final imgWidth = image.width;
    final imgHeight = image.height;
    final targetRatio = screenWidth / screenHeight;
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
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Resize to exact screen dimensions for optimal quality
    final resized = img.copyResize(
      cropped,
      width: screenWidth,
      height: screenHeight,
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
  /// Uses FlutterView to get the actual pixel dimensions.
  static Map<String, int> getScreenResolution() {
    final view = ui.PlatformDispatcher.instance.implicitView;
    if (view != null) {
      final pixelRatio = view.devicePixelRatio;
      final logicalSize = view.physicalSize;
      return {
        'width': logicalSize.width.round(),
        'height': logicalSize.height.round(),
      };
    }
    // Fallback for common Android resolution
    return {'width': 1080, 'height': 2400};
  }
}
