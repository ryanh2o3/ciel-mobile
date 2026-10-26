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
    this.onDoubleTap,
    this.overlay,
  });

  final List<Media> mediaItems;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Widget? overlay;

  @override
  State<CielMediaCarousel> createState() => _CielMediaCarouselState();
}

class _CielMediaCarouselState extends State<CielMediaCarousel> {
  late final PageController _page;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _page = PageController();
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
    return AspectRatio(
      aspectRatio: 1,
      child: GestureDetector(
        onTap: widget.onTap,
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
                return CielNetworkImage(
                  imageUrl: m.mediumUrl ?? m.thumbUrl,
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
