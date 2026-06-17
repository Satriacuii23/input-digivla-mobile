import '../core/auth/rbac.dart';

class UserModel {
  final int id;
  final String username;
  final String? fullName;
  final String? email;
  final String role;
  final String? production;

  const UserModel({
    required this.id,
    required this.username,
    this.fullName,
    this.email,
    required this.role,
    this.production,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: (json['role'] as String?) ?? 'user',
      production: json['production'] as String?,
    );
  }

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : username;
  String get roleLabel => UserRbac.roleLabel(role);
  bool get isSuperAdmin => UserRbac.normalizeRole(role) == AppRole.superadmin;
  bool get isAdmin => UserRbac.normalizeRole(role) == AppRole.admin;
  bool get canDeleteArticles => UserRbac.canDeleteArticles(role);
  bool get canManageMedia => UserRbac.canManageMedia(role);
  bool get canManageUsers => UserRbac.canManageUsers(role);
  bool get canUseTools => UserRbac.canUseTools(role);

  bool canAccessRoute(String path) => UserRbac.canAccessRoute(role, path);
  bool canWriteChannel(String channel) => UserRbac.canWriteChannel(role, channel);
  bool canQcChannel(String channel) => UserRbac.canQcChannel(role, channel);
}
