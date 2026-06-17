/// API configuration
/// LAN (VM):     http://192.168.100.50:8005
/// Luar LAN:     https://input-digivla.ngrok.app (ngrok di VM)
class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.50:8005',
  );

  /// URL ngrok untuk build APK luar jaringan
  static const publicUrl = 'https://input-digivla.ngrok.app';

  static String get apiPrefix => '$baseUrl/api';
}
