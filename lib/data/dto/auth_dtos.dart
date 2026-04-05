/// Login request body — snake_case keys for API.
Map<String, dynamic> loginRequestJson({
  required String email,
  required String password,
}) {
  return {'email': email, 'password': password};
}

/// Refresh request body.
Map<String, dynamic> refreshRequestJson({required String refreshToken}) {
  return {'refresh_token': refreshToken};
}

/// Revoke request body.
Map<String, dynamic> revokeRequestJson({required String refreshToken}) {
  return {'refresh_token': refreshToken};
}

class AuthTokensDto {
  AuthTokensDto({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  factory AuthTokensDto.fromJson(Map<String, dynamic> json) {
    return AuthTokensDto(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      accessExpiresAt: DateTime.parse(json['access_expires_at'] as String),
      refreshExpiresAt: DateTime.parse(json['refresh_expires_at'] as String),
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
}
