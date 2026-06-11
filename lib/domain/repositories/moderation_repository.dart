/// User reporting via moderation API.
// ignore: one_member_abstracts
abstract class ModerationRepository {
  Future<void> flagUser({required String userId, String? reason});
}
