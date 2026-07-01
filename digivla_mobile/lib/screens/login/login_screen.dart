import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/responsive.dart';
import '../../widgets/digivla_logo.dart';
import '../../widgets/digivla_widgets.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/auth/rbac.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_usernameCtrl.text, _passwordCtrl.text);
    if (!mounted) return;
    if (ok) {
      final role = auth.user?.role;
      context.go(UserRbac.defaultHome(role));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(auth.error ?? 'Login gagal')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final pad = AppResponsive.pagePadding(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(pad, pad, pad, pad + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    _LoginHeader(),
                    const SizedBox(height: 36),
                    _LoginFormCard(
                      formKey: _formKey,
                      usernameCtrl: _usernameCtrl,
                      passwordCtrl: _passwordCtrl,
                      usernameFocus: _usernameFocus,
                      passwordFocus: _passwordFocus,
                      obscure: _obscure,
                      loading: loading,
                      onToggleObscure: () => setState(() => _obscure = !_obscure),
                      onSubmit: _submit,
                    ),
                    const SizedBox(height: 28),
                    _LoginFooter(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Center(child: DigivlaLogo()),
        const SizedBox(height: 14),
        const Text(
          'IDS 2.0 · Daily Uploader',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        Container(
          width: 48,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFF39237),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sign in to your account',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.navy),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Manage TV, Radio, and Online media articles from your mobile device.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }
}

class _LoginFormCard extends StatelessWidget {
  const _LoginFormCard({
    required this.formKey,
    required this.usernameCtrl,
    required this.passwordCtrl,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController usernameCtrl;
  final TextEditingController passwordCtrl;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.04),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LoginField(
              controller: usernameCtrl,
              focusNode: usernameFocus,
              label: 'Username',
              hint: 'Enter username',
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => passwordFocus.requestFocus(),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Username wajib diisi' : null,
            ),
            const SizedBox(height: 18),
            _LoginField(
              controller: passwordCtrl,
              focusNode: passwordFocus,
              label: 'Password',
              hint: 'Enter password',
              icon: Icons.lock_outline,
              obscure: obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              suffix: IconButton(
                icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: AppColors.textMuted),
                onPressed: onToggleObscure,
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
            ),
            const SizedBox(height: 26),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppColors.navy,
                  disabledBackgroundColor: AppColors.navy.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: loading
                    ? const ButtonLoadingIndicator()
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 20, color: AppColors.white),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFooter extends StatefulWidget {
  @override
  State<_LoginFooter> createState() => _LoginFooterState();
}

class _LoginFooterState extends State<_LoginFooter> {
  bool _testing = false;
  String? _pingResult;

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _pingResult = null;
    });
    final api = context.read<AuthProvider>().api;
    final ok = await api.pingServer();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _pingResult = ok
          ? 'Server OK — ${ApiConfig.baseUrl}'
          : 'Server tidak terjangkau. Periksa koneksi jaringan Anda.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  ApiConfig.baseUrl,
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _testing ? null : _testConnection,
          icon: _testing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_tethering, size: 16),
          label: Text(_testing ? 'Mengecek koneksi...' : 'Test koneksi server'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        if (_pingResult != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _pingResult!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _pingResult!.startsWith('Server OK') ? AppColors.success : AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          '© Digivla IDS · Media Operations',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted.withValues(alpha: 0.85)),
        ),
      ],
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
    this.validator,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            prefixIcon: Icon(icon, size: 22, color: AppColors.navy),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.navy, width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
          ),
        ),
      ],
    );
  }
}
