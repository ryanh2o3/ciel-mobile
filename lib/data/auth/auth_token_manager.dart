import 'package:ciel_mobile/data/local/secure_refresh_token_store.dart';

/// In-memory access token + persisted refresh token (Swift `AuthSession`).
class AuthTokenManager {
  AuthTokenManager(this._store);

  final SecureRefreshTokenStore _store;

  String? _accessToken;

  String? get accessToken => _accessToken;

  Future<String?> get refreshToken => _store.readRefreshToken();

  Future<void> setTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    await _store.writeRefreshToken(refreshToken);
  }

  Future<void> updateAccessToken(String accessToken) async {
    _accessToken = accessToken;
  }

  Future<void> clear() async {
    _accessToken = null;
    await _store.clear();
  }
}
