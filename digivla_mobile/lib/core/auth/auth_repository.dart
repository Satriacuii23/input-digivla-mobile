import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../storage/token_storage.dart';
import '../../models/user.dart';

class AuthRepository {
  AuthRepository({ApiClient? api, TokenStorage? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? TokenStorage();

  final ApiClient _api;
  final TokenStorage _storage;

  ApiClient get apiClient => _api;

  Future<UserModel> login(String username, String password) async {
    final data = await _api.postJson('/auth/login', {
      'username': username.trim(),
      'password': password,
    });

    final token = data['token'] as String? ?? data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw const ApiException('Login failed — no token received');
    }

    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) {
      throw const ApiException('Login failed — invalid user data');
    }

    final user = UserModel.fromJson(userJson);
    _api.setToken(token);
    try {
      await _storage.saveToken(token, username: user.username);
    } catch (e) {
      throw ApiException('Gagal menyimpan sesi login: $e');
    }
    return user;
  }

  Future<UserModel?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;

    _api.setToken(token);
    try {
      final data = await _api.getJson('/auth/me');
      return UserModel.fromJson(data);
    } catch (_) {
      await _storage.clear();
      _api.setToken(null);
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _api.postJson('/auth/logout', {});
    } catch (_) {
      /* ignore */
    }
    await _storage.clear();
    _api.setToken(null);
  }
}
