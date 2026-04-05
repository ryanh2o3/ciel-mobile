import 'package:meta/meta.dart';

@immutable
class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String postId;
  final String body;
  final DateTime createdAt;
}
