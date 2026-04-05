import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';

/// Application auth orchestration — pure Dart (no Flutter / Riverpod).
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> login({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }

  Future<void> logout() => _repository.logout();

  /// Returns the current user if a valid session exists, otherwise `null`.
  Future<User?> restoreSession() async {
    try {
      return await _repository.fetchMe();
    } catch (_) {
      await _repository.clearLocalSession();
      return null;
    }
  }
}
