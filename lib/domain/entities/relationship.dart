import 'package:meta/meta.dart';

@immutable
class Relationship {
  const Relationship({
    required this.isFollowing,
    required this.isFollowedBy,
    required this.isBlocking,
    required this.isBlockedBy,
  });

  final bool isFollowing;
  final bool isFollowedBy;
  final bool isBlocking;
  final bool isBlockedBy;
}
