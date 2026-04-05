import 'package:ciel_mobile/domain/entities/signup_request.dart';
import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:ciel_mobile/domain/repositories/auth_repository.dart';

/// Application auth orchestration — pure Dart (no Flutter / Riverpod).
class AuthUseCase {
  AuthUseCase(this._repository);

  final AuthRepository _repository;

  Future<User> login({required String email, required String password}) {
    return _repository.login(email: email, password: password);
  }

  /// Signup then login to obtain tokens (matches Swift `AuthUseCase.signup`).
  Future<User> signup(SignupRequest request) async {
    await _repository.signup(request);
    return _repository.login(
      email: request.email,
      password: request.password,
    );
  }

  Future<void> logout() => _repository.logout();

  /// Returns the current user if a valid session exists, otherwise `null`.
  Future<User?> restoreSession() async {
    try {
      return await _repository.fetchMe();
    } on Object catch (_) {
      await _repository.clearLocalSession();
      return null;
    }
  }
}
