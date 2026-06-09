import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Preset crop shapes. The cropper *locks* to the named aspect for square
/// and portrait presets; for [story] and [free] the user may pick any
/// ratio from the preset menu.
enum CielCropPreset {
  /// 1:1 — primary post crop.
  square,

  /// 4:5 portrait — alternate post crop (Instagram-style).
  portraitFourFive,

  /// 9:16 default suggestion, but free for the user to override.
  story,

  /// No suggested aspect, no lock.
  free,
}

/// Wraps `image_picker` + `image_cropper` so the rest of the app talks in
/// terms of [XFile] and our own [CielCropPreset].
abstract final class CielImageEditor {
  /// Pick a single image and immediately open the cropper. Returns the
  /// cropped [XFile], or `null` if the user cancelled either step.
  static Future<XFile?> pickAndCrop({
    required BuildContext context,
    required CielCropPreset preset,
    ImageSource source = ImageSource.gallery,
  }) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return null;
    if (!context.mounted) return null;
    return crop(context: context, sourcePath: picked.path, preset: preset);
  }

  /// Re-open the cropper on an existing local file.
  static Future<XFile?> crop({
    required BuildContext context,
    required String sourcePath,
    required CielCropPreset preset,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final isLocked =
        preset != CielCropPreset.story && preset != CielCropPreset.free;
    final cropped = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: _aspectFor(preset),
      compressQuality: 92,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Edit photo',
          toolbarColor: scheme.surface,
          toolbarWidgetColor: scheme.onSurface,
          backgroundColor: scheme.surface,
          activeControlsWidgetColor: scheme.primary,
          lockAspectRatio: isLocked,
          hideBottomControls: false,
          aspectRatioPresets: _aspectPresets(preset),
        ),
        IOSUiSettings(
          title: 'Edit photo',
          aspectRatioLockEnabled: isLocked,
          resetAspectRatioEnabled: !isLocked,
          aspectRatioPickerButtonHidden: isLocked,
          aspectRatioPresets: _aspectPresets(preset),
        ),
      ],
    );
    return cropped == null ? null : XFile(cropped.path);
  }

  static CropAspectRatio? _aspectFor(CielCropPreset preset) {
    return switch (preset) {
      CielCropPreset.square => const CropAspectRatio(ratioX: 1, ratioY: 1),
      CielCropPreset.portraitFourFive => const CropAspectRatio(
        ratioX: 4,
        ratioY: 5,
      ),
      CielCropPreset.story => const CropAspectRatio(ratioX: 9, ratioY: 16),
      CielCropPreset.free => null,
    };
  }

  static List<CropAspectRatioPresetData> _aspectPresets(
    CielCropPreset preset,
  ) {
    return switch (preset) {
      CielCropPreset.square => const [
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.original,
      ],
      CielCropPreset.portraitFourFive => const [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
      ],
      CielCropPreset.story => const [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
        CropAspectRatioPreset.ratio16x9,
      ],
      CielCropPreset.free => const [
        CropAspectRatioPreset.original,
        CropAspectRatioPreset.square,
      ],
    };
  }
}
