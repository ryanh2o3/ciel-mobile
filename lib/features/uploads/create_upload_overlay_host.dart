import 'package:ciel_mobile/features/uploads/create_upload_state.dart';
import 'package:ciel_mobile/ui/ciel_upload_overlay.dart';
import 'package:flutter/widgets.dart';

/// Bridge between a feature's [CreateUploadState] and the
/// presentation-only [CielUploadOverlay].
class CreateUploadOverlayHost extends StatelessWidget {
  const CreateUploadOverlayHost({
    required this.state,
    required this.onRetry,
    required this.onDismiss,
    super.key,
  });

  final CreateUploadState state;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CreateUploadPreparing() => const CielUploadOverlay(
        phase: CielUploadPhase.preparing,
      ),
      CreateUploadSending(
        :final itemIndex,
        :final itemCount,
        :final overallFraction,
      ) =>
        CielUploadOverlay(
          phase: CielUploadPhase.sending,
          itemIndex: itemIndex,
          itemCount: itemCount,
          fraction: overallFraction,
        ),
      CreateUploadProcessing(:final itemIndex, :final itemCount) =>
        CielUploadOverlay(
          phase: CielUploadPhase.processing,
          itemIndex: itemIndex,
          itemCount: itemCount,
        ),
      CreateUploadFinalizing() => const CielUploadOverlay(
        phase: CielUploadPhase.finalizing,
      ),
      CreateUploadFailed(:final message) => CielUploadOverlay(
        phase: CielUploadPhase.failed,
        errorMessage: message,
        onRetry: onRetry,
        onDismiss: onDismiss,
      ),
      CreateUploadIdle() || CreateUploadDone() => const SizedBox.shrink(),
    };
  }
}
