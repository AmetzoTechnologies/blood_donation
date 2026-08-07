import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static const int maxBytes = 2 * 1024 * 1024; // 2MB API limit
  static const int targetBytes = 1500 * 1024; // keep some headroom

  static bool isImagePath(String path) {
    final ext = p.extension(path).toLowerCase();
    return const {'.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'}.contains(
      ext,
    );
  }

  /// Compresses image files under the API 2MB limit. Non-images are returned as-is.
  static Future<File> compressIfNeeded(File file) async {
    if (!isImagePath(file.path)) {
      return file;
    }

    if (!await file.exists()) {
      throw StateError(
        "Could not read the selected file. Please choose it again.",
      );
    }

    final originalSize = await file.length();
    debugPrint(
      "Image compress start: ${file.path} (${_formatBytes(originalSize)})",
    );

    if (originalSize <= targetBytes) {
      return file;
    }

    final tempDir = await getTemporaryDirectory();
    var quality = 85;
    var minWidth = 1280;
    var minHeight = 1280;
    File? bestFile;

    while (quality >= 40) {
      final outPath = p.join(
        tempDir.path,
        "compressed_${DateTime.now().millisecondsSinceEpoch}_q$quality.jpg",
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (result == null) {
        break;
      }

      final compressed = File(result.path);
      final size = await compressed.length();
      debugPrint(
        "Image compress try q=$quality size=${_formatBytes(size)}",
      );
      bestFile = compressed;

      if (size <= targetBytes) {
        return compressed;
      }

      quality -= 15;
      minWidth = (minWidth * 0.85).round();
      minHeight = (minHeight * 0.85).round();
    }

    if (bestFile != null && await bestFile.length() < originalSize) {
      final size = await bestFile.length();
      if (size > maxBytes) {
        throw StateError(
          "Image is still larger than 2MB after compression (${_formatBytes(size)}). Please choose a smaller photo.",
        );
      }
      return bestFile;
    }

    if (originalSize > maxBytes) {
      throw StateError(
        "Image is larger than 2MB and could not be compressed. Please choose a smaller photo.",
      );
    }

    return file;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    final kb = bytes / 1024;
    if (kb < 1024) return "${kb.toStringAsFixed(1)} KB";
    return "${(kb / 1024).toStringAsFixed(2)} MB";
  }
}
