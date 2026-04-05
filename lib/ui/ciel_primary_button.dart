import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Filled primary action — same layout on iOS/Android; uses Material 3 + tokens.
class CielPrimaryButton extends StatelessWidget {
  const CielPrimaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CielRadii.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: CielSpacing.lg),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(label),
      ),
    );
  }
}
