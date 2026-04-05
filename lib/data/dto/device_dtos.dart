import 'package:ciel_mobile/domain/entities/device_info.dart';

class DeviceInfoDto {
  DeviceInfoDto({
    required this.fingerprintHash,
    required this.accountCount,
    required this.riskScore,
    required this.isBlocked,
  });

  factory DeviceInfoDto.fromJson(Map<String, dynamic> json) {
    return DeviceInfoDto(
      fingerprintHash: json['fingerprint_hash'] as String,
      accountCount: (json['account_count'] as num).toInt(),
      riskScore: (json['risk_score'] as num).toInt(),
      isBlocked: json['is_blocked'] as bool,
    );
  }

  DeviceInfo toDomain() {
    return DeviceInfo(
      fingerprintHash: fingerprintHash,
      accountCount: accountCount,
      riskScore: riskScore,
      isBlocked: isBlocked,
    );
  }

  final String fingerprintHash;
  final int accountCount;
  final int riskScore;
  final bool isBlocked;
}
