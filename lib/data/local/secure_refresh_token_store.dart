import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists refresh token only (Swift `KeychainTokenStore`).
class SecureRefreshTokenStore {
  SecureRefreshTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'picshare_refresh_token';

  final FlutterSecureStorage _storage;

  Future<String?> readRefreshToken() => _storage.read(key: _key);

  Future<void> writeRefreshToken(String token) =>
      _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}
