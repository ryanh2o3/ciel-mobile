import 'package:ciel_mobile/domain/entities/invite.dart';

abstract class InviteRepository {
  Future<InviteCode> createInvite({required int daysValid});

  Future<List<InviteCode>> getInvites();

  Future<InviteStats> getInviteStats();

  Future<void> revokeInvite(String code);

  Future<bool> validateInviteCode(String code);
}
