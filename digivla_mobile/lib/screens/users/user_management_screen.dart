import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/rbac.dart';
import '../../services/user_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserService _service;
  final _searchCtrl = TextEditingController();

  List<ManagedUser> _users = [];
  List<RoleOption> _roles = [];
  bool _loading = true;
  String? _error;
  String? _filterRole;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _service = UserService(context.read<AuthProvider>().api);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _service.listRoles();
      final users = await _service.listUsers();
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final users = await _service.listUsers(
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        role: _filterRole,
        status: _filterStatus,
      );
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openForm({ManagedUser? user}) async {
    final isCreate = user == null;
    final usernameCtrl = TextEditingController(text: user?.username ?? '');
    final passwordCtrl = TextEditingController();
    final fullNameCtrl = TextEditingController(text: user?.fullName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final productionCtrl = TextEditingController(text: user?.production ?? 'production');
    var role = user?.role ?? 'staff_online';
    var status = user?.status ?? 'active';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isCreate ? 'Add User' : 'Edit User',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy),
                      ),
                      const SizedBox(height: 16),
                      if (isCreate)
                        TextField(
                          controller: usernameCtrl,
                          decoration: const InputDecoration(labelText: 'Username', hintText: 'contoh: johndoe'),
                        )
                      else
                        TextField(
                          controller: usernameCtrl,
                          enabled: false,
                          decoration: const InputDecoration(labelText: 'Username'),
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fullNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: productionCtrl,
                        decoration: const InputDecoration(labelText: 'Production'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: _roles
                            .map((r) => DropdownMenuItem(value: r.value, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setLocal(() => role = v ?? role),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'active', child: Text('Aktif')),
                          DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                        ],
                        onChanged: (v) => setLocal(() => status = v ?? status),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: isCreate ? 'Password' : 'Password Baru',
                          hintText: isCreate ? null : 'Kosongkan jika tidak diubah',
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (ok != true || !mounted) return;

    try {
      if (isCreate) {
        if (passwordCtrl.text.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password minimal 6 karakter')),
          );
          return;
        }
        await _service.createUser({
          'username': usernameCtrl.text.trim().toLowerCase(),
          'password': passwordCtrl.text,
          'full_name': fullNameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'role': role,
          'status': status,
          'production': productionCtrl.text.trim(),
        });
      } else {
        final payload = <String, dynamic>{
          'full_name': fullNameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'role': role,
          'status': status,
          'production': productionCtrl.text.trim(),
        };
        if (passwordCtrl.text.isNotEmpty) payload['password'] = passwordCtrl.text;
        await _service.updateUser(user.id, payload);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User disimpan')));
      _search();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'User Management',
      subtitle: 'Manage user accounts & roles',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_outlined),
          tooltip: 'Add user',
          onPressed: () => _openForm(),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search users…',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(onPressed: _bootstrap, icon: const Icon(Icons.refresh_outlined)),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All roles', style: TextStyle(fontSize: 12)),
                        selected: _filterRole == null,
                        onSelected: (_) { setState(() => _filterRole = null); _search(); },
                      ),
                      const SizedBox(width: 8),
                      ..._roles.map((r) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(r.label, style: const TextStyle(fontSize: 12)),
                              selected: _filterRole == r.value,
                              onSelected: (_) { setState(() => _filterRole = r.value); _search(); },
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('All status', style: TextStyle(fontSize: 12)),
                      selected: _filterStatus == null,
                      onSelected: (_) { setState(() => _filterStatus = null); _search(); },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Active', style: TextStyle(fontSize: 12)),
                      selected: _filterStatus == 'active',
                      onSelected: (_) { setState(() => _filterStatus = 'active'); _search(); },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Inactive', style: TextStyle(fontSize: 12)),
                      selected: _filterStatus == 'inactive',
                      onSelected: (_) { setState(() => _filterStatus = 'inactive'); _search(); },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Memuat user', subtitle: 'Mengambil data dari server…')
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: 'Gagal memuat', subtitle: _error)
                    : RefreshIndicator(
                        onRefresh: _bootstrap,
                        color: AppColors.navy,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final u = _users[index];
                            return DigivlaCard(
                              onTap: () => _openForm(user: u),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                                    child: Text(
                                      u.username.isNotEmpty ? u.username[0].toUpperCase() : '?',
                                      style: const TextStyle(color: AppColors.navy, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(u.username, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
                                        Text(
                                          u.roleLabel ?? UserRbac.roleLabel(u.role),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: u.status == 'active'
                                          ? Colors.green.withValues(alpha: 0.12)
                                          : Colors.grey.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      u.status == 'active' ? 'Aktif' : 'Nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: u.status == 'active' ? Colors.green.shade800 : AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
