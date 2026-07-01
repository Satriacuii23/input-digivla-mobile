/// API configuration
/// LAN (VM):     http://192.168.100.50:8005
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.50:8005',
  );

  static String get apiPrefix => '$baseUrl/api';
}
