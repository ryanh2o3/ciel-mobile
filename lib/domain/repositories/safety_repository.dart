import 'package:ciel_mobile/domain/entities/device_info.dart';
import 'package:ciel_mobile/domain/entities/trust_score.dart';

abstract class SafetyRepository {
  /// `POST /account/device/register` — body is `{ "fingerprint": "..." }`.
  Future<void> registerDevice({required String fingerprint});

  Future<List<DeviceInfo>> getRegisteredDevices();

  Future<TrustScore> fetchTrustScore();

  Future<RateLimits> fetchRateLimits();
}
