import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/media.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class EditMediaScreen extends StatefulWidget {
  const EditMediaScreen({super.key, required this.media});

  final MediaModel media;

  @override
  State<EditMediaScreen> createState() => _EditMediaScreenState();
}

class _EditMediaScreenState extends State<EditMediaScreen> {
  late final MediaService _service;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _circulationCtrl;
  late final TextEditingController _rateBwCtrl;
  late final TextEditingController _rateFcCtrl;

  List<MediaTypeModel> _types = [];
  int? _selectedType;
  String _language = 'IDN';
  bool _statusActive = true;
  String? _tier;
  bool _loading = false;
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    final m = widget.media;
    _service = MediaService(context.read<AuthProvider>().api);
    _nameCtrl = TextEditingController(text: m.mediaName);
    _circulationCtrl = TextEditingController(text: m.circulation?.toString() ?? '');
    _rateBwCtrl = TextEditingController(text: m.rateBw?.toString() ?? '');
    _rateFcCtrl = TextEditingController(text: m.rateFc?.toString() ?? '');
    _selectedType = m.mediaType;
    _language = m.language ?? 'IDN';
    _statusActive = m.status != 'Inactive';
    _tier = m.tier;
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
        _loadingTypes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedType == null) return;
    setState(() => _loading = true);
    try {
      await _service.updateMedia(widget.media.mediaId, {
        'media_name': _nameCtrl.text.trim(),
        'media_type': _selectedType,
        'language': _language,
        'status': _statusActive ? 'Active' : 'Inactive',
        if (_tier != null && _tier!.isNotEmpty) 'tier': _tier,
        'circulation': int.tryParse(_circulationCtrl.text.trim()),
        'rate_bw': double.tryParse(_rateBwCtrl.text.trim()),
        'rate_fc': double.tryParse(_rateFcCtrl.text.trim()),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media berhasil diperbarui')));
      context.go('/media');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Edit Media',
      subtitle: widget.media.mediaName,
      body: _loadingTypes
          ? const LoadingView(message: 'Memuat data media', subtitle: 'Mohon tunggu sebentar…')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
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
                              decoration: const InputDecoration(labelText: 'Media Name *', prefixIcon: Icon(Icons.newspaper_outlined)),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<int>(
                              initialValue: _selectedType,
                              decoration: const InputDecoration(labelText: 'Media Type *', prefixIcon: Icon(Icons.category_outlined)),
                              items: _types.map((t) => DropdownMenuItem(value: t.mediaTypeId, child: Text('${t.label} (#${t.mediaTypeId})'))).toList(),
                              onChanged: (v) => setState(() => _selectedType = v),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              initialValue: _tier,
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
                              initialValue: _language,
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
                            TextFormField(controller: _circulationCtrl, decoration: const InputDecoration(labelText: 'Circulation', prefixIcon: Icon(Icons.groups_outlined)), keyboardType: TextInputType.number),
                            const SizedBox(height: 14),
                            TextFormField(controller: _rateBwCtrl, decoration: const InputDecoration(labelText: 'Rate B&W', prefixIcon: Icon(Icons.payments_outlined)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                            const SizedBox(height: 14),
                            TextFormField(controller: _rateFcCtrl, decoration: const InputDecoration(labelText: 'Rate Full Color', prefixIcon: Icon(Icons.payments_outlined)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FormSection(
                        title: 'Publication Status',
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Active Status', style: TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(_statusActive ? 'Active' : 'Inactive'),
                          value: _statusActive,
                          activeTrackColor: AppColors.navy.withValues(alpha: 0.4),
                          thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.navy : null),
                          onChanged: (v) => setState(() => _statusActive = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loading ? null : _submit,
                          icon: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.save_outlined),
                          label: Text(_loading ? 'Saving…' : 'Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
