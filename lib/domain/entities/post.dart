import 'package:meta/meta.dart';

enum PostVisibility {
  public,
  followersOnly,
}

@immutable
class Post {
  const Post({
    required this.id,
    required this.ownerId,
    required this.mediaIds,
    required this.visibility,
    required this.createdAt,
    this.ownerHandle,
    this.ownerDisplayName,
    this.ownerAvatarUrl,
    this.caption,
  });

  final String id;
  final String ownerId;
  final String? ownerHandle;
  final String? ownerDisplayName;
  final String? ownerAvatarUrl;
  final List<String> mediaIds;
  final String? caption;
  final PostVisibility visibility;
  final DateTime createdAt;

  String? get primaryMediaId => mediaIds.isEmpty ? null : mediaIds.first;
}
