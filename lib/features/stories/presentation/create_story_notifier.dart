import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/domain/entities/story.dart';
import 'package:ciel_mobile/domain/usecases/media_upload_progress.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/features/uploads/upload_error_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CreateStoryController extends AutoDisposeNotifier<CreateUploadState> {
  @override
  CreateUploadState build() => const CreateUploadIdle();

  Future<bool> submit({
    required XFile image,
    required StoryVisibility visibility,
    String? caption,
  }) async {
    state = const CreateUploadPreparing();
    try {
      final normalized = await ImageNormalizer.normalizeExifOrientation(
        File(image.path),
      );
      final bytes = await normalized.readAsBytes();

      await ref
          .read(storyUseCaseProvider)
          .createStoryFromImage(
            imageBytes: bytes,
            caption: caption,
            visibility: visibility,
            onProgress: _mapProgress,
          );
      state = const CreateUploadFinalizing();
      state = const CreateUploadDone();
      return true;
    } on Object catch (e) {
      state = CreateUploadFailed(message: friendlyUploadError(e));
      return false;
    }
  }

  void reset() => state = const CreateUploadIdle();

  void _mapProgress(MediaUploadProgress p) {
    state = switch (p) {
      MediaUploadPreparing() => const CreateUploadPreparing(),
      MediaUploadSending(:final sent, :final total) => CreateUploadSending(
        itemIndex: 1,
        itemCount: 1,
        sent: sent,
        total: total,
      ),
      MediaUploadProcessing() => const CreateUploadProcessing(
        itemIndex: 1,
        itemCount: 1,
      ),
    };
  }
}

final createStoryControllerProvider =
    AutoDisposeNotifierProvider<CreateStoryController, CreateUploadState>(
      CreateStoryController.new,
    );
