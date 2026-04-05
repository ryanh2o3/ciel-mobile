import 'package:ciel_mobile/domain/entities/user.dart';
import 'package:flutter/foundation.dart';

enum AuthStatus {
  unknown,
  loading,
  authenticated,
  unauthenticated,
}

@immutable
class AuthState {
  const AuthState({
    required this.status,
    this.user,
  });

  const AuthState.unknown() : this(status: AuthStatus.unknown);

  const AuthState.loading() : this(status: AuthStatus.loading, user: null);

  const AuthState.unauthenticated()
      : this(status: AuthStatus.unauthenticated, user: null);

  final AuthStatus status;
  final User? user;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;

  AuthState copyWith({AuthStatus? status, User? user, bool clearUser = false}) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}
