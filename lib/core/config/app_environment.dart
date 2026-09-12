abstract final class AppEnvironment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mix-and-sip.devlynq.com/api/v1',
  );
  static const apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );
}
