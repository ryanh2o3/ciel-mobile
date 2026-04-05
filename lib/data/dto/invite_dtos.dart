import 'package:ciel_mobile/data/api/json_parse.dart';
import 'package:ciel_mobile/domain/entities/invite.dart';

class InviteCodeDto {
  InviteCodeDto({
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

  factory InviteCodeDto.fromJson(Map<String, dynamic> json) {
    return InviteCodeDto(
      code: json['code'] as String,
      createdBy: json['created_by']?.toString(),
      usedBy: json['used_by']?.toString(),
      createdAt: parseApiDateTime(json['created_at'] as String),
      usedAt: json['used_at'] != null
          ? parseApiDateTime(json['used_at'] as String)
          : null,
      expiresAt: parseApiDateTime(json['expires_at'] as String),
      isValid: json['is_valid'] as bool,
      inviteType: json['invite_type'] as String,
      useCount: (json['use_count'] as num).toInt(),
      maxUses: (json['max_uses'] as num).toInt(),
    );
  }

  InviteCode toDomain() {
    return InviteCode(
      code: code,
      createdBy: createdBy,
      usedBy: usedBy,
      createdAt: createdAt,
      usedAt: usedAt,
      expiresAt: expiresAt,
      isValid: isValid,
      inviteType: inviteType,
      useCount: useCount,
      maxUses: maxUses,
    );
  }

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

class InviteStatsDto {
  InviteStatsDto({
    required this.invitesSent,
    required this.successfulInvites,
    required this.remainingInvites,
    required this.maxInvites,
  });

  factory InviteStatsDto.fromJson(Map<String, dynamic> json) {
    return InviteStatsDto(
      invitesSent: (json['invites_sent'] as num).toInt(),
      successfulInvites: (json['successful_invites'] as num).toInt(),
      remainingInvites: (json['remaining_invites'] as num).toInt(),
      maxInvites: (json['max_invites'] as num).toInt(),
    );
  }

  InviteStats toDomain() {
    return InviteStats(
      invitesSent: invitesSent,
      successfulInvites: successfulInvites,
      remainingInvites: remainingInvites,
      maxInvites: maxInvites,
    );
  }

  final int invitesSent;
  final int successfulInvites;
  final int remainingInvites;
  final int maxInvites;
}

class InviteValidationResponseDto {
  InviteValidationResponseDto({required this.isValid});

  factory InviteValidationResponseDto.fromJson(Map<String, dynamic> json) {
    return InviteValidationResponseDto(
      isValid: json['is_valid'] as bool,
    );
  }

  final bool isValid;
}
