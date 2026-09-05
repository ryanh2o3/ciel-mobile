import 'package:cached_network_image/cached_network_image.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

enum CielStoryRingStyle {
  none,
  unseen,
  seen,
}

/// Circular avatar with forced fill clip, optional story ring and badge.
class CielAvatar extends StatelessWidget {
  const CielAvatar({
    super.key,
    this.imageUrl,
    this.size = CielAvatarSize.md,
    this.label,
    this.ring = CielStoryRingStyle.none,
    this.badge,
    this.onTap,
  });

  final String? imageUrl;
  final double size;
  final String? label;
  final CielStoryRingStyle ring;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasRing = ring != CielStoryRingStyle.none;
    final ringPad = hasRing ? CielStoryRing.width + CielStoryRing.gap : 0.0;
    final outer = size + ringPad * 2;
    final initial = _initial(label);

    Color? ringColor;
    switch (ring) {
      case CielStoryRingStyle.none:
        ringColor = null;
      case CielStoryRingStyle.unseen:
        ringColor = scheme.primary;
      case CielStoryRingStyle.seen:
        ringColor = scheme.outlineVariant;
    }

    Widget avatar = SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: scheme.primaryContainer,
        ),
        child: ClipOval(
          child: _AvatarImage(
            imageUrl: imageUrl,
            size: size,
            initial: initial,
            scheme: scheme,
          ),
        ),
      ),
    );

    if (hasRing && ringColor != null) {
      avatar = Container(
        width: outer,
        height: outer,
        padding: const EdgeInsets.all(CielStoryRing.gap),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: CielStoryRing.width),
        ),
        child: avatar,
      );
    }

    if (badge != null) {
      avatar = SizedBox(
        width: outer,
        height: outer,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
          ],
        ),
      );
    }

    if (onTap == null) {
      return avatar;
    }
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: avatar,
    );
  }

  static String _initial(String? label) {
    final t = label?.trim() ?? '';
    if (t.isEmpty) {
      return '?';
    }
    return String.fromCharCode(t.runes.first).toUpperCase();
  }
}

class _AvatarImage extends StatelessWidget {
  const _AvatarImage({
    required this.imageUrl,
    required this.size,
    required this.initial,
    required this.scheme,
  });

  final String? imageUrl;
  final double size;
  final String initial;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _Initial(initial: initial, scheme: scheme);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(
        color: scheme.primaryContainer,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, _, _) => _Initial(initial: initial, scheme: scheme),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({required this.initial, required this.scheme});

  final String initial;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: scheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
