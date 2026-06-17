import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client, this.timeout = const Duration(seconds: 20)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;
  String? _token;

  static const _networkError =
      'Tidak dapat terhubung ke server. Pastikan HP terhubung WiFi yang sama dengan VM (192.168.100.x) dan API URL benar di bawah form login.';

  void setToken(String? token) => _token = token;
  String? get token => _token;

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final res = await _send(() => _client.put(
          Uri.parse('${ApiConfig.apiPrefix}$path'),
          headers: _jsonHeaders,
          body: jsonEncode(body),
        ));
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final res = await _send(() => _client.delete(
          Uri.parse('${ApiConfig.apiPrefix}$path'),
          headers: _jsonHeaders,
        ));
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _send(() => _client.post(
          Uri.parse('${ApiConfig.apiPrefix}$path'),
          headers: _jsonHeaders,
          body: jsonEncode(body),
        ));
    return _parseResponse(res);
  }

  Future<Map<String, dynamic>> getJson(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.apiPrefix}$path').replace(queryParameters: query);
    final res = await _send(() => _client.get(uri, headers: _jsonHeaders));
    return _parseResponse(res);
  }

  Future<List<dynamic>> getJsonList(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.apiPrefix}$path').replace(queryParameters: query);
    final res = await _send(() => _client.get(uri, headers: _jsonHeaders));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) return decoded;
      if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
      return [];
    }
    _parseResponse(res);
    return [];
  }

  Future<Map<String, dynamic>> uploadMultipart(
    String path, {
    required String fileField,
    required List<int> bytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('${ApiConfig.apiPrefix}$path');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }
    if (fields != null) {
      request.fields.addAll(fields);
    }
    request.files.add(http.MultipartFile.fromBytes(fileField, bytes, filename: filename));

    final streamed = await request.send().timeout(timeout);
    final res = await http.Response.fromStream(streamed);
    return _parseResponse(res);
  }

  /// Quick connectivity check — hits API root (no auth).
  Future<bool> pingServer() async {
    try {
      final res = await _send(() => _client.get(Uri.parse('${ApiConfig.baseUrl}/health')));
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException(
        'Koneksi ke server timeout. Periksa jaringan WiFi atau gunakan APK build ngrok jika di luar LAN.',
      );
    } on SocketException {
      throw const ApiException(_networkError);
    } on http.ClientException {
      throw const ApiException(_networkError);
    } on HandshakeException {
      throw const ApiException(
        'Gagal handshake SSL. Jika di luar LAN, build APK dengan URL ngrok HTTPS.',
      );
    }
  }

  Map<String, dynamic> _parseResponse(http.Response res) {
    Map<String, dynamic> data = {};
    if (res.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {
        data = {'detail': res.body};
      }
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return data;
    }

    final detail = data['detail'];
    String message;
    if (detail is String) {
      message = detail;
    } else if (detail is List && detail.isNotEmpty) {
      message = detail.map((e) => e['msg'] ?? e.toString()).join(', ');
    } else {
      message = data['error'] as String? ?? _statusFallback(res.statusCode);
    }
    throw ApiException(message, statusCode: res.statusCode);
  }

  static String _statusFallback(int status) {
    switch (status) {
      case 401:
        return 'Username atau password salah';
      case 403:
        return 'Akun tidak aktif atau tidak memiliki akses';
      case 404:
        return 'Endpoint API tidak ditemukan — periksa versi backend';
      case 500:
        return 'Server error — coba lagi atau hubungi administrator';
      default:
        return 'Request gagal (HTTP $status)';
    }
  }

  void dispose() => _client.close();
}
