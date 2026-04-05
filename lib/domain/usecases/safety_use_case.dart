import 'package:ciel_mobile/domain/entities/device_info.dart';
import 'package:ciel_mobile/domain/entities/trust_score.dart';
import 'package:ciel_mobile/domain/repositories/safety_repository.dart';

class SafetyUseCase {
  SafetyUseCase(this._repository);

  final SafetyRepository _repository;

  Future<void> registerDevice({required String fingerprint}) {
    return _repository.registerDevice(fingerprint: fingerprint);
  }

  Future<List<DeviceInfo>> getRegisteredDevices() {
    return _repository.getRegisteredDevices();
  }

  Future<TrustScore> fetchTrustScore() => _repository.fetchTrustScore();

  Future<RateLimits> fetchRateLimits() => _repository.fetchRateLimits();
}
