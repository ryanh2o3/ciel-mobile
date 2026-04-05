import 'package:meta/meta.dart';

@immutable
class Like {
  const Like({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
}
