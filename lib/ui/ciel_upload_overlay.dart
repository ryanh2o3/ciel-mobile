import 'package:ciel_mobile/ui/ciel_primary_button.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

enum CielUploadPhase { preparing, sending, processing, finalizing, failed }

/// Full-screen scrim + card showing upload phase, progress, and a retry
/// affordance on failure. Driven by props — feature code maps its own
/// sealed state to these primitives.
class CielUploadOverlay extends StatelessWidget {
  const CielUploadOverlay({
    required this.phase,
    super.key,
    this.itemIndex,
    this.itemCount,
    this.fraction,
    this.errorMessage,
    this.onRetry,
    this.onDismiss,
  });

  final CielUploadPhase phase;

  /// 1-based index of the asset currently being processed. May be `null`
  /// when not applicable (preparing, finalizing, failed).
  final int? itemIndex;
  final int? itemCount;

  /// Overall progress in `[0, 1]`. `null` renders an indeterminate bar.
  final double? fraction;

  /// Required when [phase] is [CielUploadPhase.failed].
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  bool get _isFailed => phase == CielUploadPhase.failed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.scrim.withValues(alpha: 0.55),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(CielSpacing.lg),
          child: Material(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(CielRadii.xl),
            elevation: 8,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(CielSpacing.lg),
                child: _isFailed
                    ? _buildFailed(context)
                    : _buildProgress(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _phaseTitle(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: CielSpacing.xs),
        Text(
          _phaseSubtitle(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: CielSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(CielRadii.sm),
          child: LinearProgressIndicator(
            value: fraction,
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: CielSpacing.sm),
            Expanded(
              child: Text(
                "Couldn't share",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: CielSpacing.sm),
        Text(
          errorMessage ?? 'Something went wrong. Please try again.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: CielSpacing.lg),
        if (onRetry != null)
          CielPrimaryButton(
            label: 'Try again',
            onPressed: onRetry,
          ),
        if (onDismiss != null) ...[
          const SizedBox(height: CielSpacing.sm),
          TextButton(
            onPressed: onDismiss,
            child: const Text('Cancel'),
          ),
        ],
      ],
    );
  }

  String _phaseTitle() {
    switch (phase) {
      case CielUploadPhase.preparing:
        return 'Preparing…';
      case CielUploadPhase.sending:
        if (itemCount != null && itemCount! > 1 && itemIndex != null) {
          return 'Uploading $itemIndex of $itemCount…';
        }
        return 'Uploading…';
      case CielUploadPhase.processing:
        return 'Processing…';
      case CielUploadPhase.finalizing:
        return 'Almost done…';
      case CielUploadPhase.failed:
        return "Couldn't share";
    }
  }

  String _phaseSubtitle() {
    switch (phase) {
      case CielUploadPhase.preparing:
        return 'Getting things ready.';
      case CielUploadPhase.sending:
        if (fraction != null) {
          final percent = (fraction! * 100).clamp(0, 100).round();
          return '$percent%';
        }
        return 'Sending your photo.';
      case CielUploadPhase.processing:
        return 'PicShare is finishing up your photo.';
      case CielUploadPhase.finalizing:
        return 'Publishing.';
      case CielUploadPhase.failed:
        return '';
    }
  }
}
