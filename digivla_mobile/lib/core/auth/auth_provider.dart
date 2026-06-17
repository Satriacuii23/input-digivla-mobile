import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'auth_repository.dart';
import '../../models/user.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository}) : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  UserModel? _user;
  bool _loading = true;
  String? _error;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get loading => _loading;
  String? get error => _error;
  ApiClient get api => _repository.apiClient;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();
    try {
      _user = await _repository.restoreSession();
      _error = null;
    } catch (e) {
      _user = null;
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _user = await _repository.login(username, password);
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('ApiException: ', '');
      _user = null;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    _user = null;
    notifyListeners();
  }
}
