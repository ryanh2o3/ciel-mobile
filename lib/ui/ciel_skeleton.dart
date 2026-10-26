import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Lightweight shimmer-style placeholder block.
class CielSkeleton extends StatefulWidget {
  const CielSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<CielSkeleton> createState() => _CielSkeletonState();
}

class _CielSkeletonState extends State<CielSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: 0.45 + (_controller.value * 0.4),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: base,
              borderRadius:
                  widget.borderRadius ?? BorderRadius.circular(CielRadii.sm),
            ),
          ),
        );
      },
    );
  }
}

/// Square grid-cell skeleton for profile / search post grids.
class CielSkeletonGrid extends StatelessWidget {
  const CielSkeletonGrid({super.key, this.count = 9});

  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: count,
      itemBuilder: (_, _) => const CielSkeleton(
        height: double.infinity,
        borderRadius: BorderRadius.zero,
      ),
    );
  }
}
