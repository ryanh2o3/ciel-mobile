import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:ciel_mobile/domain/usecases/media_upload_progress.dart';

class MediaUseCase {
  MediaUseCase(this._repository);

  final MediaRepository _repository;

  Future<MediaUploadIntent> createUploadIntent({
    required String contentType,
    required int bytes,
  }) {
    return _repository.createUploadIntent(
      contentType: contentType,
      bytes: bytes,
    );
  }

  Future<void> uploadBytes({
    required String uploadUrl,
    required Map<String, String> headers,
    required List<int> data,
    void Function(int sent, int total)? onSendProgress,
  }) {
    return _repository.uploadBytes(
      uploadUrl: uploadUrl,
      headers: headers,
      data: data,
      onSendProgress: onSendProgress,
    );
  }

  Future<void> completeUpload(String uploadId) {
    return _repository.completeUpload(uploadId);
  }

  Future<MediaUploadStatus> uploadStatus(String uploadId) {
    return _repository.uploadStatus(uploadId);
  }

  Future<Media> fetchMedia(String id) => _repository.fetchMedia(id);

  Future<void> deleteMedia(String id) => _repository.deleteMedia(id);

  /// Upload raw image bytes and poll until `processed_media_id` is available.
  ///
  /// [onProgress] receives phase transitions (preparing → sending → processing)
  /// and per-byte upload progress.
  Future<String> uploadImageAndWaitForMediaId({
    required List<int> data,
    String contentType = 'image/jpeg',
    void Function(MediaUploadProgress progress)? onProgress,
  }) async {
    onProgress?.call(const MediaUploadPreparing());
    final intent = await createUploadIntent(
      contentType: contentType,
      bytes: data.length,
    );
    await uploadBytes(
      uploadUrl: intent.uploadUrl,
      headers: intent.headers,
      data: data,
      onSendProgress: onProgress == null
          ? null
          : (sent, total) => onProgress(
              MediaUploadSending(
                sent: sent,
                total: total <= 0 ? data.length : total,
              ),
            ),
    );
    onProgress?.call(const MediaUploadProcessing());
    await completeUpload(intent.uploadId);

    const maxAttempts = 20;
    var delayMs = 1000;
    for (var i = 0; i < maxAttempts; i++) {
      final status = await uploadStatus(intent.uploadId);
      if (status.status == 'completed' && status.processedMediaId != null) {
        return status.processedMediaId!;
      }
      if (status.status == 'failed') {
        throw StateError('Media processing failed');
      }
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      delayMs = (delayMs * 2).clamp(1000, 5000);
    }
    throw StateError('Media processing timeout');
  }
}
