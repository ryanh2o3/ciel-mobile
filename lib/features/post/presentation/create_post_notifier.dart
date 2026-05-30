import 'dart:io';

import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/media/image_normalizer.dart';
import 'package:ciel_mobile/domain/usecases/media_upload_progress.dart';
import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/features/uploads/upload_error_mapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CreatePostController extends AutoDisposeNotifier<CreateUploadState> {
  @override
  CreateUploadState build() => const CreateUploadIdle();

  Future<bool> submit({
    required List<XFile> images,
    String? caption,
  }) async {
    if (images.isEmpty) {
      state = const CreateUploadFailed(
        message: 'Choose at least one photo to share.',
      );
      return false;
    }
    final total = images.length;
    state = CreateUploadPreparing(itemCount: total);
    try {
      final media = ref.read(mediaUseCaseProvider);
      final post = ref.read(postUseCaseProvider);

      final ids = <String>[];
      for (var i = 0; i < images.length; i++) {
        final itemIndex = i + 1;
        final file = images[i];
        final normalized = await ImageNormalizer.normalizeExifOrientation(
          File(file.path),
        );
        final bytes = await normalized.readAsBytes();
        ids.add(
          await media.uploadImageAndWaitForMediaId(
            data: bytes,
            onProgress: (p) {
              state = switch (p) {
                MediaUploadPreparing() => CreateUploadPreparing(
                  itemIndex: itemIndex,
                  itemCount: total,
                ),
                MediaUploadSending(:final sent, total: final byteTotal) =>
                  CreateUploadSending(
                    itemIndex: itemIndex,
                    itemCount: total,
                    sent: sent,
                    total: byteTotal,
                  ),
                MediaUploadProcessing() => CreateUploadProcessing(
                  itemIndex: itemIndex,
                  itemCount: total,
                ),
              };
            },
          ),
        );
      }

      state = const CreateUploadFinalizing();
      await post.createPost(mediaIds: ids, caption: caption);
      state = const CreateUploadDone();
      return true;
    } on Object catch (e) {
      state = CreateUploadFailed(message: friendlyUploadError(e));
      return false;
    }
  }

  void reset() => state = const CreateUploadIdle();
}

final createPostControllerProvider =
    AutoDisposeNotifierProvider<CreatePostController, CreateUploadState>(
      CreatePostController.new,
    );
