import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Presentation metadata for an audience option. Decoupled from the
/// domain enum so the same sheet can render any visibility type.
class CielAudienceOption<T> {
  const CielAudienceOption({
    required this.value,
    required this.icon,
    required this.title,
    required this.description,
  });

  final T value;
  final IconData icon;
  final String title;
  final String description;
}

/// Modal bottom sheet that picks one [CielAudienceOption]. Returns the
/// selected value, or `null` if the sheet was dismissed.
Future<T?> showCielAudiencePicker<T>({
  required BuildContext context,
  required List<CielAudienceOption<T>> options,
  required T selected,
  String title = 'Who can see this?',
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            CielSpacing.md,
            0,
            CielSpacing.md,
            CielSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: CielSpacing.sm,
                  bottom: CielSpacing.md,
                ),
                child: Text(
                  title,
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
              ),
              for (final option in options)
                Padding(
                  padding: const EdgeInsets.only(bottom: CielSpacing.sm),
                  child: _AudienceTile<T>(
                    option: option,
                    isSelected: option.value == selected,
                    onTap: () => Navigator.of(sheetContext).pop(option.value),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _AudienceTile<T> extends StatelessWidget {
  const _AudienceTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CielAudienceOption<T> option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isSelected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(CielRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(CielRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CielSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                option.icon,
                color: isSelected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: CielSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? scheme.onPrimaryContainer.withValues(alpha: 0.85)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: CielSpacing.sm),
                  child: Icon(
                    Icons.check_circle,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
