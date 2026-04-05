import 'package:ciel_mobile/domain/entities/media.dart';

/// Result of `POST /media/upload` — domain-level summary for uploads.
class MediaUploadIntent {
  const MediaUploadIntent({
    required this.uploadId,
    required this.uploadUrl,
    required this.headers,
  });

  final String uploadId;
  final String uploadUrl;
  final Map<String, String> headers;
}

class MediaUploadStatus {
  const MediaUploadStatus({
    required this.status,
    this.processedMediaId,
  });

  final String status;
  final String? processedMediaId;
}

abstract class MediaRepository {
  Future<MediaUploadIntent> createUploadIntent({
    required String contentType,
    required int bytes,
  });

  Future<void> uploadBytes({
    required String uploadUrl,
    required Map<String, String> headers,
    required List<int> data,
  });

  Future<void> completeUpload(String uploadId);

  Future<MediaUploadStatus> uploadStatus(String uploadId);

  Future<Media> fetchMedia(String id);

  Future<void> deleteMedia(String id);
}
