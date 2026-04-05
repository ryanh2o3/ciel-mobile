import 'package:ciel_mobile/domain/entities/invite.dart';
import 'package:ciel_mobile/domain/repositories/invite_repository.dart';

class InviteUseCase {
  InviteUseCase(this._repository);

  final InviteRepository _repository;

  Future<InviteCode> createInvite({required int daysValid}) {
    return _repository.createInvite(daysValid: daysValid);
  }

  Future<List<InviteCode>> getInvites() => _repository.getInvites();

  Future<InviteStats> getInviteStats() => _repository.getInviteStats();

  Future<void> revokeInvite(String code) => _repository.revokeInvite(code);

  Future<bool> validateInviteCode(String code) {
    return _repository.validateInviteCode(code);
  }
}
