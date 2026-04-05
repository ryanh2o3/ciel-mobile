import 'package:meta/meta.dart';

/// Invite row from `GET /invites` — aligned with Ciel-backend `InviteCode`.
@immutable
class InviteCode {
  const InviteCode({
    required this.code,
    required this.createdAt,
    required this.expiresAt,
    required this.isValid,
    required this.inviteType,
    required this.useCount,
    required this.maxUses,
    this.createdBy,
    this.usedBy,
    this.usedAt,
  });

  final String code;
  final String? createdBy;
  final String? usedBy;
  final DateTime createdAt;
  final DateTime? usedAt;
  final DateTime expiresAt;
  final bool isValid;
  final String inviteType;
  final int useCount;
  final int maxUses;
}

@immutable
class InviteStats {
  const InviteStats({
    required this.invitesSent,
    required this.successfulInvites,
    required this.remainingInvites,
    required this.maxInvites,
  });

  final int invitesSent;
  final int successfulInvites;
  final int remainingInvites;
  final int maxInvites;
}
