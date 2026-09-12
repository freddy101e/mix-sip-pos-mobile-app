/// Legacy compatibility file. Secrets must be supplied through secure backend
/// configuration and are intentionally not embedded in the mobile app.
abstract final class ApiConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mix-and-sip.devlynq.com/api/v1',
  );
}

const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
