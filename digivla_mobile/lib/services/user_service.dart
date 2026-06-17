import '../core/api/api_client.dart';
import '../models/user.dart';

class RoleOption {
  const RoleOption({required this.value, required this.label});
  final String value;
  final String label;

  factory RoleOption.fromJson(Map<String, dynamic> json) => RoleOption(
        value: json['value'] as String,
        label: json['label'] as String,
      );
}

class UserService {
  UserService(this._api);

  final ApiClient _api;

  Future<List<ManagedUser>> listUsers({String? search, String? status, String? role}) async {
    final query = <String, String>{};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (role != null && role.isNotEmpty) query['role'] = role;

    final data = await _api.getJsonList('/users', query: query.isEmpty ? null : query);
    return data.map((e) => ManagedUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<RoleOption>> listRoles() async {
    final data = await _api.getJsonList('/users/roles');
    return data.map((e) => RoleOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ManagedUser> createUser(Map<String, dynamic> payload) async {
    final data = await _api.postJson('/users', payload);
    return ManagedUser.fromJson(data as Map<String, dynamic>);
  }

  Future<ManagedUser> updateUser(int id, Map<String, dynamic> payload) async {
    final data = await _api.putJson('/users/$id', payload);
    return ManagedUser.fromJson(data as Map<String, dynamic>);
  }
}

class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.role,
    required this.status,
    this.fullName,
    this.email,
    this.roleLabel,
    this.production,
    this.lastLogin,
  });

  final int id;
  final String username;
  final String? fullName;
  final String? email;
  final String role;
  final String? roleLabel;
  final String? production;
  final String status;
  final String? lastLogin;

  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
        id: json['id'] as int,
        username: json['username'] as String,
        fullName: json['full_name'] as String?,
        email: json['email'] as String?,
        role: json['role'] as String,
        roleLabel: json['role_label'] as String?,
        production: json['production'] as String?,
        status: json['status'] as String? ?? 'active',
        lastLogin: json['last_login'] as String?,
      );
}
