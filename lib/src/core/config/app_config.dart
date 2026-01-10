class AppConfig {
  // For iOS Simulator, use 127.0.0.1 or localhost (simulator shares Mac's network)
  // For physical device, use your Mac's local IP (e.g., 192.168.0.111)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://app.drjoekhoury.com/api',
  );

  static const String appName = 'MedCode';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}




















