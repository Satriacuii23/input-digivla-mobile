import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/media.dart';
import '../../services/media_service.dart';
import '../../widgets/digivla_widgets.dart';

class MediaMultiAddTab extends StatefulWidget {
  const MediaMultiAddTab({super.key});

  @override
  State<MediaMultiAddTab> createState() => _MediaMultiAddTabState();
}

class _MediaMultiAddTabState extends State<MediaMultiAddTab> {
  late final MediaService _service;
  final List<_MediaRow> _rows = [_MediaRow()];
  List<MediaTypeModel> _types = [];
  bool _loadingTypes = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service = MediaService(context.read<AuthProvider>().api);
    _loadTypes();
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTypes() async {
    try {
      final types = await _service.listTypes();
      if (!mounted) return;
      setState(() {
        _types = types;
        for (final r in _rows) {
          r.typeId ??= types.isNotEmpty ? types.first.mediaTypeId : null;
        }
        _loadingTypes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTypes = false);
    }
  }

  Future<void> _submit() async {
    final payload = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final name = r.nameCtrl.text.trim();
      if (name.isEmpty || r.typeId == null) continue;
      payload.add({
        'media_name': name,
        'media_type': r.typeId,
        'language': r.language,
        'status': r.active ? 'Active' : 'Inactive',
        if (r.tier != null) 'tier': r.tier,
      });
    }
    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Isi minimal 1 media')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await _service.createMediaBatch(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.createdCount} media created')),
      );
      context.go('/media');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTypes) return const LoadingView(message: 'Loading types');
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Multi Add Media',
          description: 'Add up to 50 media entries in one submit (same as web Multi tab).',
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < _rows.length; i++) ...[
          FormSection(
            title: 'Media #${i + 1}',
            child: Column(
              children: [
                TextField(
                  controller: _rows[i].nameCtrl,
                  decoration: const InputDecoration(labelText: 'Media Name *', isDense: true),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _rows[i].typeId,
                  decoration: const InputDecoration(labelText: 'Type *', isDense: true),
                  items: _types.map((t) => DropdownMenuItem(value: t.mediaTypeId, child: Text(t.label))).toList(),
                  onChanged: (v) => setState(() => _rows[i].typeId = v),
                ),
                if (_rows.length > 1)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() {
                        _rows[i].dispose();
                        _rows.removeAt(i);
                      }),
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                      label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (_rows.length < 50)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              final r = _MediaRow();
              r.typeId = _types.isNotEmpty ? _types.first.mediaTypeId : null;
              _rows.add(r);
            }),
            icon: const Icon(Icons.add),
            label: const Text('Add row'),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.save_outlined),
            label: Text(_submitting ? 'Saving…' : 'Save all'),
          ),
        ),
      ],
    );
  }
}

class _MediaRow {
  final nameCtrl = TextEditingController();
  int? typeId;
  String language = 'IDN';
  String? tier;
  bool active = true;

  void dispose() => nameCtrl.dispose();
}
