import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/media.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class AddMediaScreen extends StatefulWidget {
  const AddMediaScreen({super.key});

  @override
  State<AddMediaScreen> createState() => _AddMediaScreenState();
}

class _AddMediaScreenState extends State<AddMediaScreen> {
  late final MediaService _service;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _circulationCtrl = TextEditingController();
  final _rateBwCtrl = TextEditingController();
  final _rateFcCtrl = TextEditingController();

  List<MediaTypeModel> _types = [];
  int? _selectedType;
  String _language = 'IDN';
  bool _statusActive = true;
  String? _tier;
  bool _loading = false;
  bool _loadingTypes = true;
  bool _checkingDup = false;
  String? _dupWarning;

  @override
  void initState() {
    super.initState();
    _service = MediaService(context.read<AuthProvider>().api);
    _loadTypes();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _circulationCtrl.dispose();
    _rateBwCtrl.dispose();
    _rateFcCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _service.listTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        _selectedType = types.isNotEmpty ? types.first.mediaTypeId : null;
        _loadingTypes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  Future<void> _checkDuplicate() async {
    final name = _nameCtrl.text.trim();
    if (name.length < 2) {
      setState(() => _dupWarning = null);
      return;
    }
    setState(() => _checkingDup = true);
    try {
      final dup = await _service.checkDuplicate(name);
      if (!mounted) return;
      setState(() {
        _dupWarning = dup != null ? 'Media "${dup['media_name']}" sudah ada (ID ${dup['media_id']})' : null;
        _checkingDup = false;
      });
    } catch (_) {
      if (mounted) setState(() => _checkingDup = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedType == null || _dupWarning != null) return;
    setState(() => _loading = true);
    try {
      await _service.createMedia(
        mediaName: _nameCtrl.text,
        mediaType: _selectedType!,
        language: _language,
        status: _statusActive ? 'Active' : 'Inactive',
        tier: _tier,
        circulation: int.tryParse(_circulationCtrl.text.trim()),
        rateBw: double.tryParse(_rateBwCtrl.text.trim()),
        rateFc: double.tryParse(_rateFcCtrl.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media berhasil ditambahkan')));
      context.go('/media');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Add Media',
      subtitle: 'Single entry',
      body: _loadingTypes
          ? const LoadingView(message: 'Menyiapkan formulir', subtitle: 'Memuat data…')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const PageHeader(
                  title: 'Add Media',
                  description: 'Field selaras dengan web: Basic Information, Rates & Circulation, Publication Status.',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      FormSection(
                        title: 'Basic Information',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: const InputDecoration(labelText: 'Media Name *', hintText: 'e.g. cnnindonesia.com', prefixIcon: Icon(Icons.newspaper_outlined)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                              onFieldSubmitted: (_) => _checkDuplicate(),
                              onEditingComplete: _checkDuplicate,
                            ),
                            if (_checkingDup)
                              const Padding(padding: EdgeInsets.only(top: 8), child: Text('Checking duplicate…', style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
                            if (_dupWarning != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.error.withValues(alpha: 0.3))),
                                  child: Text(_dupWarning!, style: const TextStyle(fontSize: 12, color: AppColors.error)),
                                ),
                              ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              value: _selectedType,
                              decoration: const InputDecoration(labelText: 'Media Type *', prefixIcon: Icon(Icons.category_outlined)),
                              items: _types.map((t) => DropdownMenuItem(value: t.mediaTypeId, child: Text('${t.label} (#${t.mediaTypeId})'))).toList(),
                              onChanged: (v) => setState(() => _selectedType = v),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _tier,
                              decoration: const InputDecoration(labelText: 'Tier', prefixIcon: Icon(Icons.star_outline)),
                              items: const [
                                DropdownMenuItem(value: null, child: Text('—')),
                                DropdownMenuItem(value: 'Tier 1', child: Text('Tier 1')),
                                DropdownMenuItem(value: 'Tier 2', child: Text('Tier 2')),
                                DropdownMenuItem(value: 'Tier 3', child: Text('Tier 3')),
                              ],
                              onChanged: (v) => setState(() => _tier = v),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _language,
                              decoration: const InputDecoration(labelText: 'Language', prefixIcon: Icon(Icons.language_outlined)),
                              items: const [
                                DropdownMenuItem(value: 'IDN', child: Text('Indonesia (IDN)')),
                                DropdownMenuItem(value: 'ENG', child: Text('English (ENG)')),
                              ],
                              onChanged: (v) => setState(() => _language = v ?? 'IDN'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormSection(
                        title: 'Rates & Circulation',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _circulationCtrl,
                              decoration: const InputDecoration(labelText: 'Circulation', prefixIcon: Icon(Icons.groups_outlined)),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _rateBwCtrl,
                              decoration: const InputDecoration(labelText: 'Rate B&W', prefixIcon: Icon(Icons.payments_outlined)),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _rateFcCtrl,
                              decoration: const InputDecoration(labelText: 'Rate Full Color', prefixIcon: Icon(Icons.payments_outlined)),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormSection(
                        title: 'Publication Status',
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_statusActive ? 'Active' : 'Inactive', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          value: _statusActive,
                          activeColor: AppColors.navy,
                          onChanged: (v) => setState(() => _statusActive = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(onPressed: _loading ? null : () => context.go('/media'), child: const Text('Cancel')),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: (_loading || _dupWarning != null) ? null : _submit,
                              icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.save_outlined),
                              label: Text(_loading ? 'Saving…' : 'Save Media'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
