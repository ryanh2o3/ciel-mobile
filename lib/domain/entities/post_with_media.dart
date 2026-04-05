import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/entities/post.dart';
import 'package:meta/meta.dart';

@immutable
class PostWithMedia {
  const PostWithMedia({
    required this.post,
    required this.mediaItems,
  });

  final Post post;
  final List<Media> mediaItems;

  String get id => post.id;

  Media? get primaryMedia => mediaItems.isEmpty ? null : mediaItems.first;

  bool get hasMultipleImages => mediaItems.length > 1;
}
