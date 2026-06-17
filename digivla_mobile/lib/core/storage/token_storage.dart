import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _keyToken = 'auth_token';
  static const _keyUsername = 'username';

  static const _storageOptions = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final FlutterSecureStorage _storage;

  TokenStorage({FlutterSecureStorage? storage}) : _storage = storage ?? _storageOptions;

  Future<void> saveToken(String token, {String? username}) async {
    await _storage.write(key: _keyToken, value: token);
    if (username != null) {
      await _storage.write(key: _keyUsername, value: username);
    }
  }

  Future<String?> readToken() => _storage.read(key: _keyToken);

  Future<String?> readUsername() => _storage.read(key: _keyUsername);

  Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyUsername);
  }
}
