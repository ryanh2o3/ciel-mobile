import 'package:ciel_mobile/domain/repositories/moderation_repository.dart';

class ModerationUseCase {
  ModerationUseCase(this._repository);

  final ModerationRepository _repository;

  Future<void> reportUser({required String userId, String? reason}) {
    return _repository.flagUser(userId: userId, reason: reason);
  }
}
