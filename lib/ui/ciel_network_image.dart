import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:ciel_mobile/ui/ciel_skeleton.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image that fills its parent constraints (feed / grid / avatar).
class CielNetworkImage extends StatefulWidget {
  const CielNetworkImage({
    required this.imageUrl,
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  State<CielNetworkImage> createState() => _CielNetworkImageState();
}

class _CielNetworkImageState extends State<CielNetworkImage> {
  int _retryKey = 0;

  @override
  void didUpdateWidget(covariant CielNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) _retryKey = 0;
  }

  Future<void> _retry(String url) async {
    try {
      await CachedNetworkImage.evictFromCache(url);
    } on Object catch (_) {
      // Retry with the existing cache entry if eviction isn't available.
    }
    if (mounted) setState(() => _retryKey++);
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: const _ImageFallback(
          icon: Icons.image_not_supported_outlined,
          message: 'Image unavailable',
        ),
      );
    }
    return CachedNetworkImage(
      key: ValueKey('$url-$_retryKey'),
      imageUrl: url,
      fit: widget.fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          final placeholderWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : width;
          final placeholderHeight =
              constraints.maxHeight.isFinite && constraints.maxHeight > 0
              ? constraints.maxHeight
              : (height ?? 220);
          return CielSkeleton(
            width: placeholderWidth,
            height: placeholderHeight,
            borderRadius: BorderRadius.zero,
          );
        },
      ),
      errorWidget: (context, failedUrl, error) {
        if (kDebugMode) {
          debugPrint('[CielNetworkImage] failed to load: $failedUrl');
          debugPrint('[CielNetworkImage] error: $error');
        }
        return _ImageFallback(
          icon: Icons.broken_image_outlined,
          message: 'Couldn’t load photo',
          onRetry: () => unawaited(_retry(failedUrl)),
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: scheme.outline, size: 28),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null)
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
