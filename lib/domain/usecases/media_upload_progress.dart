/// Progress events emitted by `MediaUseCase.uploadImageAndWaitForMediaId`.
sealed class MediaUploadProgress {
  const MediaUploadProgress();
}

/// Negotiating an upload intent with the server (presigned URL).
class MediaUploadPreparing extends MediaUploadProgress {
  const MediaUploadPreparing();
}

/// Streaming bytes to the presigned URL.
class MediaUploadSending extends MediaUploadProgress {
  const MediaUploadSending({required this.sent, required this.total});

  final int sent;
  final int total;

  /// Fraction in `[0, 1]`. Returns `0` when [total] is not yet known.
  double get fraction => total <= 0 ? 0 : (sent / total).clamp(0, 1).toDouble();
}

/// Bytes are uploaded; the server is processing the asset.
class MediaUploadProcessing extends MediaUploadProgress {
  const MediaUploadProcessing();
}
