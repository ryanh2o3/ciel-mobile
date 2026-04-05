import 'package:ciel_mobile/domain/entities/user.dart';

/// Contract for authentication and session persistence.
abstract class AuthRepository {
  /// Clears in-memory and persisted credentials without calling the network.
  Future<void> clearLocalSession();

  /// Loads the current user from `GET /auth/me` (refresh flow handled by HTTP client).
  Future<User> fetchMe();

  /// Signs in and returns the current user.
  Future<User> login({required String email, required String password});

  /// Revokes refresh token on the server and clears local session.
  Future<void> logout();
}
