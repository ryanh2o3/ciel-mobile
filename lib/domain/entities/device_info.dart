import 'package:meta/meta.dart';

/// Device summary from `GET /account/devices` (Ciel backend).
@immutable
class DeviceInfo {
  const DeviceInfo({
    required this.fingerprintHash,
    required this.accountCount,
    required this.riskScore,
    required this.isBlocked,
  });

  final String fingerprintHash;
  final int accountCount;
  final int riskScore;
  final bool isBlocked;
}
