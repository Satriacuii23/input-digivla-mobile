import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../services/media_service.dart';
import '../../widgets/digivla_widgets.dart';

class MediaBulkImportTab extends StatefulWidget {
  const MediaBulkImportTab({super.key});

  @override
  State<MediaBulkImportTab> createState() => _MediaBulkImportTabState();
}

class _MediaBulkImportTabState extends State<MediaBulkImportTab> {
  late final MediaService _service;
  PlatformFile? _file;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _service = MediaService(context.read<AuthProvider>().api);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _file = result.files.first);
    }
  }

  Future<void> _import() async {
    if (_file?.bytes == null) return;
    setState(() => _importing = true);
    try {
      final result = await _service.bulkImportFile(
        bytes: _file!.bytes!,
        filename: _file!.name,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import selesai: ${result.createdCount} media created')),
      );
      context.go('/media');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PageHeader(
          title: 'Bulk Import',
          description: 'Upload Excel/CSV template to import many media at once (same as web Bulk Import tab).',
        ),
        const SizedBox(height: 16),
        DigivlaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Template columns: Media Name, Media Type, Language, Status, Tier, Circulation, Rate B&W, Rate FC', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_file?.name ?? 'Pilih file Excel/CSV'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: (_importing || _file?.bytes == null) ? null : _import,
                icon: _importing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.cloud_upload_outlined),
                label: Text(_importing ? 'Importing…' : 'Import file'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
