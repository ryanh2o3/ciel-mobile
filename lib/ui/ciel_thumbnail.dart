import 'dart:io';

import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Small rounded thumbnail. Renders [file] when present; otherwise shows
/// a placeholder with a photo icon and an optional label. Always tappable
/// so callers can use it both as the empty-state CTA and as a preview.
class CielThumbnail extends StatelessWidget {
  const CielThumbnail({
    super.key,
    this.file,
    this.size = 72,
    this.placeholderLabel,
    this.onTap,
    this.badgeText,
  });

  final File? file;
  final double size;
  final String? placeholderLabel;
  final VoidCallback? onTap;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(CielRadii.lg);

    final content = file != null
        ? Image.file(file!, fit: BoxFit.cover)
        : _Placeholder(
            label: placeholderLabel,
            scheme: scheme,
          );

    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              content,
              if (badgeText != null)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.scrim.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(CielRadii.sm),
                    ),
                    child: Text(
                      badgeText!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.scheme, this.label});

  final ColorScheme scheme;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: scheme.onSurfaceVariant,
          size: 24,
        ),
        if (label != null) ...[
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
