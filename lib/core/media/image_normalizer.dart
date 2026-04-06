import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

class ImageNormalizer {
  const ImageNormalizer._();

  /// Returns a file whose pixel data is rotated/mirrored per EXIF orientation.
  ///
  /// If normalization fails (or platform unsupported), returns the original
  /// file.
  static Future<File> normalizeExifOrientation(File file) async {
    if (kIsWeb) {
      return file;
    }
    try {
      return await FlutterExifRotation.rotateImage(path: file.path);
    } on Object {
      return file;
    }
  }
}
