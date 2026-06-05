class ApiConfig {
  // Use 10.0.2.2 for Android emulator; use your machine's LAN IP for physical devices.
  static const String baseUrl = 'http://127.0.0.1:5000';

  static const String healthEndpoint = '$baseUrl/health';
  static const String statusEndpoint = '$baseUrl/api/status';
}
