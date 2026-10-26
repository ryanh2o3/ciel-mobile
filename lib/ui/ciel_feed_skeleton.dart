import 'package:ciel_mobile/ui/ciel_skeleton.dart';
import 'package:ciel_mobile/ui/tokens.dart';
import 'package:flutter/material.dart';

/// Placeholder cards that preserve the feed's shape during its first load.
class CielFeedSkeleton extends StatelessWidget {
  const CielFeedSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => const _FeedSkeletonCard(),
        childCount: count,
      ),
    );
  }
}

class _FeedSkeletonCard extends StatelessWidget {
  const _FeedSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: const EdgeInsets.only(bottom: CielSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: CielSpacing.md,
              vertical: CielSpacing.sm,
            ),
            child: Row(
              children: [
                const CielSkeleton(
                  width: CielAvatarSize.sm,
                  height: CielAvatarSize.sm,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                const SizedBox(width: CielSpacing.sm),
                CielSkeleton(
                  width: width * 0.34,
                  height: 14,
                  borderRadius: BorderRadius.circular(999),
                ),
              ],
            ),
          ),
          CielSkeleton(
            height: width,
            borderRadius: BorderRadius.zero,
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              CielSpacing.md,
              CielSpacing.md,
              CielSpacing.md,
              CielSpacing.xs,
            ),
            child: CielSkeleton(width: 100, height: 14),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              CielSpacing.md,
              CielSpacing.xs,
              CielSpacing.xl,
              CielSpacing.md,
            ),
            child: CielSkeleton(height: 13),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant.withValues(
              alpha: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
