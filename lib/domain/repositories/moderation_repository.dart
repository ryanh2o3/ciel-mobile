abstract class ModerationRepository {
  Future<void> flagUser({required String userId, String? reason});

  Future<void> flagPost({required String postId, String? reason});
}
