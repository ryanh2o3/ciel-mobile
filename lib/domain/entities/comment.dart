import 'package:meta/meta.dart';

@immutable
class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.postId,
    required this.body,
    required this.createdAt,
    this.userHandle,
    this.userDisplayName,
  });

  final String id;
  final String userId;
  final String postId;
  final String body;
  final DateTime createdAt;
  final String? userHandle;
  final String? userDisplayName;

  String get authorLabel {
    if (userDisplayName != null && userDisplayName!.isNotEmpty) {
      return userDisplayName!;
    }
    if (userHandle != null && userHandle!.isNotEmpty) {
      return '@$userHandle';
    }
    return 'User';
  }
}
