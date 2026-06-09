import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

enum CielPhotoSource { camera, library }

/// Bottom sheet asking the user where their photo should come from.
/// Returns the chosen source, or `null` if the sheet was dismissed.
Future<CielPhotoSource?> showCielPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<CielPhotoSource>(
    context: context,
    showDragHandle: true,
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
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                title: 'Take photo',
                description: 'Use the camera right now.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(CielPhotoSource.camera),
              ),
              const SizedBox(height: CielSpacing.sm),
              _SourceTile(
                icon: Icons.photo_library_outlined,
                title: 'Choose from library',
                description: 'Pick an existing photo.',
                onTap: () =>
                    Navigator.of(sheetContext).pop(CielPhotoSource.library),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(CielRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(CielRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(CielSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: scheme.onSurfaceVariant),
              const SizedBox(width: CielSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
