import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Network image that fills its parent constraints (feed / grid / avatar).
class CielNetworkImage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      placeholder: (_, _) => SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, failedUrl, error) {
        if (kDebugMode) {
          debugPrint('[CielNetworkImage] failed to load: $failedUrl');
          debugPrint('[CielNetworkImage] error: $error');
        }
        return SizedBox(
          width: width,
          height: height,
          child: ColoredBox(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              Icons.broken_image_outlined,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        );
      },
    );
  }
}
