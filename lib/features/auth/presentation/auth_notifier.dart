import 'package:ciel_mobile/app/providers/dependency_providers.dart';
import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/domain/usecases/auth_use_case.dart';
import 'package:ciel_mobile/features/auth/presentation/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  AuthUseCase get _auth => ref.read(authUseCaseProvider);

  Future<void> restoreSession() async {
    state = const AuthState.loading();
    final user = await _auth.restoreSession();
    if (user != null) {
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final user = await _auth.login(email: email, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return null;
    } on AppException catch (e) {
      state = const AuthState.unauthenticated();
      return e.message;
    } on Object catch (_) {
      state = const AuthState.unauthenticated();
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.logout();
    state = const AuthState.unauthenticated();
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
