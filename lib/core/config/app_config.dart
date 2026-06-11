/// Runtime configuration (API base URL via `--dart-define`).
class AppConfig {
  AppConfig({
    required this.apiBaseUrl,
    required this.privacyPolicyUrl,
    required this.termsOfUseUrl,
  });

  factory AppConfig.fromEnvironment() {
    const base = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    );
    const privacy = String.fromEnvironment(
      'PRIVACY_POLICY_URL',
      defaultValue: defaultPrivacyPolicyUrl,
    );
    const terms = String.fromEnvironment(
      'TERMS_OF_USE_URL',
      defaultValue: defaultTermsOfUseUrl,
    );
    final normalized = base.endsWith('/')
        ? base.substring(0, base.length - 1)
        : base;
    return AppConfig(
      apiBaseUrl: normalized,
      privacyPolicyUrl: privacy,
      termsOfUseUrl: terms,
    );
  }

  /// Default matches Swift `AppContainer` production URL.
  static const String defaultApiBaseUrl = 'https://api.ciel-social.eu/v1';

  static const String defaultPrivacyPolicyUrl =
      'https://ciel-social.eu/privacy';

  static const String defaultTermsOfUseUrl = 'https://ciel-social.eu/terms';

  final String apiBaseUrl;
  final String privacyPolicyUrl;
  final String termsOfUseUrl;
}
