import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../services/media_reach_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class MediaReachScreen extends StatefulWidget {
  const MediaReachScreen({super.key});

  @override
  State<MediaReachScreen> createState() => _MediaReachScreenState();
}

class _MediaReachScreenState extends State<MediaReachScreen> {
  late final MediaReachService _service;
  final _namesCtrl = TextEditingController();
  MediaReachJob? _job;
  bool _running = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = MediaReachService(context.read<AuthProvider>().api);
  }

  @override
  void dispose() {
    _namesCtrl.dispose();
    super.dispose();
  }

  List<String> _parseNames() {
    return _namesCtrl.text.split(RegExp(r'[\n\r,]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls', 'csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;
    final file = result.files.first;
    try {
      final parsed = await _service.parseTargets(bytes: file.bytes!, filename: file.name);
      if (!mounted) return;
      setState(() => _namesCtrl.text = parsed.names.join('\n'));
      if (parsed.skipped > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${parsed.skipped} rows skipped')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _startCrawl() async {
    final names = _parseNames();
    if (names.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter media names or upload file')));
      return;
    }
    setState(() {
      _running = true;
      _error = null;
      _job = null;
    });
    try {
      var job = await _service.startCrawl(names);
      while (!job.isDone && mounted) {
        setState(() => _job = job);
        await Future.delayed(const Duration(seconds: 2));
        job = await _service.getJob(job.jobId);
      }
      if (!mounted) return;
      setState(() {
        _job = job;
        _running = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('ApiException: ', '');
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Media Reach',
      subtitle: 'SimilarWeb crawler',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const PageHeader(
            title: 'Media Reach',
            description: 'Crawl SimilarWeb data for media targets — aligned with web Tools → Media Reach.',
          ),
          const SizedBox(height: 16),
          FormSection(
            title: 'Targets',
            child: Column(
              children: [
                TextField(
                  controller: _namesCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'One media name or domain per line\ne.g. detik.com',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: _pickFile, icon: const Icon(Icons.upload_file_outlined), label: const Text('Upload Excel/CSV')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _startCrawl,
              icon: _running ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.travel_explore_outlined),
              label: Text(_running ? 'Crawling…' : 'Start crawl'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            AlertBanner(tone: AlertTone.error, message: _error!),
          ],
          if (_job != null) ...[
            const SizedBox(height: 20),
            FormSection(
              title: 'Job ${_job!.jobId}',
              subtitle: 'Status: ${_job!.status} · ${_job!.completed}/${_job!.total}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_job!.currentMedia != null)
                    Text('Current: ${_job!.currentMedia}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: _job!.total == 0 ? null : _job!.completed / _job!.total,
                    color: AppColors.navy,
                  ),
                  if (_job!.results.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ..._job!.results.take(20).map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${r['media_name'] ?? r['domain'] ?? '—'} · visits: ${r['total_visits'] ?? '—'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
