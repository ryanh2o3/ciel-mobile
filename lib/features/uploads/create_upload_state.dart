/// Lifecycle state for a single create-something-from-image flow. Shared
/// between the story and post create notifiers so the upload overlay only
/// needs to know about one type.
sealed class CreateUploadState {
  const CreateUploadState();
}

class CreateUploadIdle extends CreateUploadState {
  const CreateUploadIdle();
}

/// Resolving local image bytes and negotiating an upload intent.
class CreateUploadPreparing extends CreateUploadState {
  const CreateUploadPreparing({this.itemIndex = 1, this.itemCount = 1});

  /// 1-based index of the asset currently being uploaded.
  final int itemIndex;

  /// Total assets in this submission.
  final int itemCount;
}

/// Streaming the current asset's bytes to storage.
class CreateUploadSending extends CreateUploadState {
  const CreateUploadSending({
    required this.itemIndex,
    required this.itemCount,
    required this.sent,
    required this.total,
  });

  final int itemIndex;
  final int itemCount;
  final int sent;
  final int total;

  double get itemFraction =>
      total <= 0 ? 0 : (sent / total).clamp(0, 1).toDouble();

  /// Overall fraction across all items, in `[0, 1]`.
  double get overallFraction => itemCount <= 0
      ? 0
      : (((itemIndex - 1) + itemFraction) / itemCount).clamp(0, 1).toDouble();
}

/// Bytes are uploaded; the server is processing this asset.
class CreateUploadProcessing extends CreateUploadState {
  const CreateUploadProcessing({
    required this.itemIndex,
    required this.itemCount,
  });

  final int itemIndex;
  final int itemCount;
}

/// All assets processed; creating the story / post record.
class CreateUploadFinalizing extends CreateUploadState {
  const CreateUploadFinalizing();
}

class CreateUploadDone extends CreateUploadState {
  const CreateUploadDone();
}

class CreateUploadFailed extends CreateUploadState {
  const CreateUploadFailed({required this.message});

  final String message;
}

extension CreateUploadStateX on CreateUploadState {
  bool get isInFlight =>
      this is CreateUploadPreparing ||
      this is CreateUploadSending ||
      this is CreateUploadProcessing ||
      this is CreateUploadFinalizing;
}
