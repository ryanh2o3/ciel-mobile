/// Runtime configuration (API base URL via `--dart-define`).
class AppConfig {
  AppConfig({required this.apiBaseUrl});

  factory AppConfig.fromEnvironment() {
    const base = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: defaultApiBaseUrl,
    );
    final normalized =
        base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    return AppConfig(apiBaseUrl: normalized);
  }

  /// Default matches Swift `AppContainer` production URL.
  static const String defaultApiBaseUrl = 'https://api.ciel-social.eu/v1';

  final String apiBaseUrl;
}
