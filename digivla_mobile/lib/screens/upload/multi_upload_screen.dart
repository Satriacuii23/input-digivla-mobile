import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/article.dart';
import '../../models/media.dart';
import '../../services/article_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

const _maxArticles = 50;

class MultiUploadEntry {
  MediaModel? media;
  DateTime date = DateTime.now();
  final titleCtrl = TextEditingController();
  final contentCtrl = TextEditingController();
  final journalistCtrl = TextEditingController();
  final timeCtrl = TextEditingController();
  final durationCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  final pagesCtrl = TextEditingController();
  final mmColCtrl = TextEditingController();
  PlatformFile? file;
  bool selected = true;

  void dispose() {
    titleCtrl.dispose();
    contentCtrl.dispose();
    journalistCtrl.dispose();
    timeCtrl.dispose();
    durationCtrl.dispose();
    urlCtrl.dispose();
    pagesCtrl.dispose();
    mmColCtrl.dispose();
  }
}

class MultiUploadScreen extends StatefulWidget {
  const MultiUploadScreen({super.key, required this.channel});

  final ArticleChannel channel;

  @override
  State<MultiUploadScreen> createState() => _MultiUploadScreenState();
}

class _MultiUploadScreenState extends State<MultiUploadScreen> {
  late final ArticleService _articleService;
  late final MediaService _mediaService;
  final _scrapeCtrl = TextEditingController();
  final List<MultiUploadEntry> _entries = [MultiUploadEntry()];
  List<MediaModel> _mediaOptions = [];
  bool _loadingMedia = true;
  bool _scraping = false;
  int _scrapeProgress = 0;
  int _scrapeProgressTotal = 0;
  String? _scrapeCurrentUrl;
  int _scrapeOk = 0;
  int _scrapeFail = 0;
  final List<int> _scrapeDurations = [];
  bool _submitting = false;
  int _progress = 0;
  int _progressTotal = 0;

  @override
  void initState() {
    super.initState();
    _articleService = ArticleService(context.read<AuthProvider>().api);
    _mediaService = MediaService(context.read<AuthProvider>().api);
    _loadMedia();
  }

  @override
  void dispose() {
    _scrapeCtrl.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _loadMedia() async {
    final typeId = widget.channel.mediaTypeId;
    if (typeId == null) return;
    try {
      final list = await _mediaService.listByType(typeId);
      if (!mounted) return;
      setState(() {
        _mediaOptions = list;
        for (final e in _entries) {
          e.media = list.isNotEmpty ? list.first : null;
        }
        _loadingMedia = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  void _addEntry() {
    if (_entries.length >= _maxArticles) return;
    setState(() {
      final e = MultiUploadEntry();
      e.media = _mediaOptions.isNotEmpty ? _mediaOptions.first : null;
      _entries.add(e);
    });
  }

  void _removeEntry(int i) {
    if (_entries.length <= 1) return;
    setState(() {
      _entries[i].dispose();
      _entries.removeAt(i);
    });
  }

  List<String> _parseUrls(String text) {
    return text.split(RegExp(r'[\n\r]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).take(_maxArticles).toList();
  }

  String _formatEta(int remaining) {
    if (_scrapeDurations.isEmpty || remaining <= 0) return 'Menghitung estimasi…';
    final avgMs = _scrapeDurations.reduce((a, b) => a + b) ~/ _scrapeDurations.length;
    final sec = ((avgMs * remaining) / 1000).ceil();
    if (sec < 60) return '~$sec detik lagi';
    final min = sec ~/ 60;
    final rem = sec % 60;
    return rem > 0 ? '~$min mnt $rem dtk lagi' : '~$min menit lagi';
  }

  void _applyScrapeResult(OnlineScrapeResult r) {
    final e = MultiUploadEntry();
    e.media = _mediaOptions.where((m) => m.mediaId == r.mediaId).firstOrNull ?? (_mediaOptions.isNotEmpty ? _mediaOptions.first : null);
    if (r.title != null) e.titleCtrl.text = r.title!;
    if (r.content != null) e.contentCtrl.text = r.content!;
    if (r.journalist != null) e.journalistCtrl.text = r.journalist!;
    if (r.url != null) e.urlCtrl.text = r.url!;
    if (r.pages != null) e.pagesCtrl.text = '${r.pages}';
    if (r.mmCol != null) e.mmColCtrl.text = '${r.mmCol}';
    if (r.datee != null) {
      final d = DateTime.tryParse(r.datee!);
      if (d != null) e.date = d;
    }
    _entries.add(e);
  }

  Future<void> _scrapeUrls() async {
    final urls = _parseUrls(_scrapeCtrl.text);
    if (urls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan URL (satu per baris)')));
      return;
    }
    setState(() {
      _scraping = true;
      _scrapeProgress = 0;
      _scrapeProgressTotal = urls.length;
      _scrapeCurrentUrl = urls.first;
      _scrapeOk = 0;
      _scrapeFail = 0;
      _scrapeDurations.clear();
    });
    try {
      for (final e in _entries) {
        e.dispose();
      }
      _entries.clear();

      for (var i = 0; i < urls.length; i++) {
        final url = urls[i];
        if (!mounted) return;
        setState(() {
          _scrapeCurrentUrl = url;
          _scrapeProgress = i;
        });
        final started = DateTime.now();
        try {
          final r = await _articleService.scrapeOnlineUrl(url);
          if (r.success) {
            _applyScrapeResult(r);
            _scrapeOk++;
          } else {
            _scrapeFail++;
          }
        } catch (_) {
          _scrapeFail++;
        }
        _scrapeDurations.add(DateTime.now().difference(started).inMilliseconds);
        if (mounted) setState(() => _scrapeProgress = i + 1);
      }

      if (!mounted) return;
      if (_entries.isEmpty) {
        _entries.add(MultiUploadEntry()..media = _mediaOptions.isNotEmpty ? _mediaOptions.first : null);
      }
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scrape selesai: $_scrapeOk berhasil${_scrapeFail > 0 ? ', $_scrapeFail gagal' : ''}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) {
        setState(() {
          _scraping = false;
          _scrapeCurrentUrl = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    final selected = _entries.where((e) => e.selected && e.media != null && e.titleCtrl.text.trim().isNotEmpty).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 artikel dengan title & media')));
      return;
    }
    setState(() {
      _submitting = true;
      _progress = 0;
      _progressTotal = selected.length;
    });
    var ok = 0;
    var fail = 0;
    for (final e in selected) {
      try {
        final dateStr = DateFormat('yyyy-MM-dd').format(e.date);
        String? filePath;
        if (e.file != null && widget.channel != ArticleChannel.online && e.file!.bytes != null) {
          final upload = await _articleService.uploadMediaFile(
            channel: widget.channel,
            bytes: e.file!.bytes!,
            filename: e.file!.name,
            mediaId: '${e.media!.mediaId}',
          );
          filePath = upload['dbPath'] as String?;
        }
        switch (widget.channel) {
          case ArticleChannel.tv:
            await _articleService.createTv(
              mediaId: e.media!.mediaId,
              title: e.titleCtrl.text,
              datee: dateStr,
              content: e.contentCtrl.text,
              journalist: e.journalistCtrl.text,
              timee: e.timeCtrl.text,
              duration: e.durationCtrl.text,
              filee: filePath,
            );
            break;
          case ArticleChannel.radio:
            await _articleService.createRadio(
              mediaId: e.media!.mediaId,
              title: e.titleCtrl.text,
              datee: dateStr,
              content: e.contentCtrl.text,
              journalist: e.journalistCtrl.text,
              timee: e.timeCtrl.text,
              duration: e.durationCtrl.text,
              filee: filePath,
            );
            break;
          case ArticleChannel.online:
            await _articleService.createOnline(
              mediaId: e.media!.mediaId,
              title: e.titleCtrl.text,
              datee: dateStr,
              content: e.contentCtrl.text,
              journalist: e.journalistCtrl.text,
              url: e.urlCtrl.text,
              pages: int.tryParse(e.pagesCtrl.text),
              mmCol: double.tryParse(e.mmColCtrl.text),
            );
            break;
        }
        ok++;
      } catch (_) {
        fail++;
      }
      if (mounted) setState(() => _progress++);
    }
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$ok berhasil${fail > 0 ? ', $fail gagal' : ''}')));
    if (ok > 0) context.go(widget.channel.listRoute);
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Multi Upload ${widget.channel.label}',
      subtitle: '${_entries.length}/$_maxArticles',
      body: _loadingMedia
          ? const LoadingView(message: 'Memuat daftar media', subtitle: 'Menyiapkan multi upload…')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (widget.channel == ArticleChannel.online) ...[
                  FormSection(
                    title: 'Scrape URLs',
                    subtitle: 'Satu URL per baris — max $_maxArticles',
                    child: Column(
                      children: [
                        TextField(
                          controller: _scrapeCtrl,
                          maxLines: 5,
                          decoration: const InputDecoration(hintText: 'https://example.com/article-1\nhttps://example.com/article-2'),
                        ),
                        const SizedBox(height: 12),
                        if (_scraping) ...[
                          DigivlaCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navy),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Meng-crawl artikel… $_scrapeProgress/$_scrapeProgressTotal',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navy),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                LinearProgressIndicator(
                                  value: _scrapeProgressTotal == 0 ? null : _scrapeProgress / _scrapeProgressTotal,
                                  color: AppColors.navy,
                                  backgroundColor: AppColors.border,
                                ),
                                if (_scrapeCurrentUrl != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _scrapeCurrentUrl!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Text(
                                  '${_formatEta(_scrapeProgressTotal - _scrapeProgress)} · OK $_scrapeOk${_scrapeFail > 0 ? ' · Gagal $_scrapeFail' : ''}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _scraping ? null : _scrapeUrls,
                            icon: _scraping ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_fix_high_outlined),
                            label: Text(_scraping ? 'Scraping $_scrapeProgress/$_scrapeProgressTotal…' : 'Scrape & Fill Forms'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Articles (${_entries.length}/$_maxArticles)', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
                    if (_entries.length < _maxArticles)
                      TextButton.icon(onPressed: _addEntry, icon: const Icon(Icons.add_outlined), label: const Text('Add Row')),
                  ],
                ),
                const SizedBox(height: 8),
                if (_submitting)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(value: _progressTotal == 0 ? null : _progress / _progressTotal, color: AppColors.navy, backgroundColor: AppColors.border),
                  ),
                for (var i = 0; i < _entries.length; i++) ...[
                  _EntryCard(
                    index: i,
                    entry: _entries[i],
                    channel: widget.channel,
                    mediaOptions: _mediaOptions,
                    onRemove: _entries.length > 1 ? () => _removeEntry(i) : null,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: Text(_submitting ? 'Uploading $_progress/$_progressTotal…' : 'Upload Selected'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.index,
    required this.entry,
    required this.channel,
    required this.mediaOptions,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final MultiUploadEntry entry;
  final ArticleChannel channel;
  final List<MediaModel> mediaOptions;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Article #${index + 1}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(value: entry.selected, onChanged: (v) { entry.selected = v ?? true; onChanged(); }, activeColor: AppColors.navy),
              const Text('Include in upload', style: TextStyle(fontSize: 13)),
              const Spacer(),
              if (onRemove != null) IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), onPressed: onRemove),
            ],
          ),
          DropdownButtonFormField<MediaModel>(
            initialValue: entry.media,
            decoration: const InputDecoration(labelText: 'Media *', isDense: true),
            items: mediaOptions.map((m) => DropdownMenuItem(value: m, child: Text(m.mediaName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) { entry.media = v; onChanged(); },
          ),
          const SizedBox(height: 10),
          TextFormField(controller: entry.titleCtrl, decoration: const InputDecoration(labelText: 'Title *', isDense: true)),
          const SizedBox(height: 10),
          TextFormField(controller: entry.contentCtrl, decoration: const InputDecoration(labelText: 'Content', isDense: true), maxLines: 3),
          if (channel == ArticleChannel.online) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: entry.journalistCtrl,
              decoration: const InputDecoration(labelText: 'Journalist', prefixIcon: Icon(Icons.person_outline, size: 20), isDense: true),
            ),
            const SizedBox(height: 10),
            TextFormField(controller: entry.urlCtrl, decoration: const InputDecoration(labelText: 'URL', isDense: true)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: entry.pagesCtrl, decoration: const InputDecoration(labelText: 'Pages', isDense: true), keyboardType: TextInputType.number)),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: entry.mmColCtrl, decoration: const InputDecoration(labelText: 'MM Col', isDense: true), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            ]),
          ] else ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: entry.timeCtrl, decoration: const InputDecoration(labelText: 'Time WIB', isDense: true))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(controller: entry.durationCtrl, decoration: const InputDecoration(labelText: 'Duration', isDense: true), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 10),
            TextFormField(
              controller: entry.journalistCtrl,
              decoration: const InputDecoration(labelText: 'Anchor / Journalist', prefixIcon: Icon(Icons.person_outline, size: 20), isDense: true),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final type = channel == ArticleChannel.radio ? FileType.audio : FileType.video;
                final r = await FilePicker.platform.pickFiles(type: type);
                if (r != null && r.files.isNotEmpty) { entry.file = r.files.first; onChanged(); }
              },
              icon: const Icon(Icons.attach_file_outlined, size: 18),
              label: Text(entry.file?.name ?? 'Attach file (optional)', style: const TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
