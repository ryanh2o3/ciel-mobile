import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/ui/ciel_network_image.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Square PageView of media with page dots when more than one image.
class CielMediaCarousel extends StatefulWidget {
  const CielMediaCarousel({
    required this.mediaItems,
    super.key,
    this.onTap,
    this.onTapPage,
    this.onDoubleTap,
    this.overlay,
    this.heroTagPrefix,
    this.initialPage = 0,
  });

  final List<Media> mediaItems;
  final VoidCallback? onTap;
  final ValueChanged<int>? onTapPage;
  final VoidCallback? onDoubleTap;
  final Widget? overlay;
  final String? heroTagPrefix;
  final int initialPage;

  @override
  State<CielMediaCarousel> createState() => _CielMediaCarouselState();
}

class _CielMediaCarouselState extends State<CielMediaCarousel> {
  late final PageController _page;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialPage;
    _page = PageController(initialPage: widget.initialPage);
  }

  void _handleTap() {
    final onTapPage = widget.onTapPage;
    if (onTapPage != null) {
      onTapPage(_index);
    } else {
      widget.onTap?.call();
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.mediaItems;
    if (items.isEmpty) {
      return const AspectRatio(
        aspectRatio: 1,
        child: CielNetworkImage(imageUrl: null),
      );
    }

    final multi = items.length > 1;
    final first = items.first;
    final mediaRatio = first.height == 0
        ? 1.0
        : (first.width / first.height).clamp(0.8, 1.91);
    return AspectRatio(
      aspectRatio: mediaRatio,
      child: GestureDetector(
        onTap: _handleTap,
        onDoubleTap: widget.onDoubleTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _page,
              itemCount: items.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final m = items[i];
                final image = CielNetworkImage(
                  imageUrl: m.mediumUrl ?? m.thumbUrl,
                );
                final prefix = widget.heroTagPrefix;
                return prefix == null
                    ? image
                    : Hero(
                        tag: '$prefix:$i',
                        child: image,
                      );
              },
            ),
            if (widget.overlay != null) widget.overlay!,
            if (multi)
              Positioned(
                top: CielSpacing.sm,
                right: CielSpacing.sm,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(CielRadii.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: CielSpacing.sm,
                      vertical: CielSpacing.xs,
                    ),
                    child: Semantics(
                      liveRegion: true,
                      label: 'Photo ${_index + 1} of ${items.length}',
                      child: Text(
                        '${_index + 1}/${items.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (multi)
              Positioned(
                left: 0,
                right: 0,
                bottom: CielSpacing.sm,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(items.length, (i) {
                    final active = i == _index;
                    return AnimatedContainer(
                      duration: CielDurations.fast,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: active ? 7 : 5,
                      height: active ? 7 : 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.45),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
