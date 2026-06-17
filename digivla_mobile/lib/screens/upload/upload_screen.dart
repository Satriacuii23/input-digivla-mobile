import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key, required this.channel});

  final ArticleChannel channel;

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  late final ArticleService _articleService;
  late final MediaService _mediaService;
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _journalistCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _durationCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController();
  final _mmColCtrl = TextEditingController();

  List<MediaModel> _mediaOptions = [];
  MediaModel? _selectedMedia;
  DateTime _date = DateTime.now();
  PlatformFile? _pickedFile;
  bool _loadingMedia = true;
  bool _submitting = false;
  bool _scraping = false;
  List<DuplicateArticle> _duplicates = [];
  Timer? _dupTimer;

  @override
  void initState() {
    super.initState();
    final api = context.read<AuthProvider>().api;
    _articleService = ArticleService(api);
    _mediaService = MediaService(api);
    _loadMedia();
    _titleCtrl.addListener(_scheduleDuplicateCheck);
    _contentCtrl.addListener(_scheduleDuplicateCheck);
  }

  @override
  void dispose() {
    _dupTimer?.cancel();
    _titleCtrl.removeListener(_scheduleDuplicateCheck);
    _contentCtrl.removeListener(_scheduleDuplicateCheck);
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _journalistCtrl.dispose();
    _timeCtrl.dispose();
    _durationCtrl.dispose();
    _urlCtrl.dispose();
    _pagesCtrl.dispose();
    _mmColCtrl.dispose();
    super.dispose();
  }

  void _scheduleDuplicateCheck() {
    _dupTimer?.cancel();
    _dupTimer = Timer(const Duration(milliseconds: 800), _checkDuplicate);
  }

  Future<void> _checkDuplicate() async {
    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty && content.isEmpty) {
      if (mounted) setState(() => _duplicates = []);
      return;
    }
    try {
      final dups = await _articleService.checkDuplicate(
        channel: widget.channel,
        title: title,
        content: content,
        mediaId: _selectedMedia?.mediaId,
      );
      if (mounted) setState(() => _duplicates = dups);
    } catch (_) {
      if (mounted) setState(() => _duplicates = []);
    }
  }

  Future<void> _loadMedia() async {
    final typeId = widget.channel.mediaTypeId;
    if (typeId == null) return;
    try {
      final list = await _mediaService.listByType(typeId);
      if (!mounted) return;
      setState(() {
        _mediaOptions = list;
        _selectedMedia = list.isNotEmpty ? list.first : null;
        _loadingMedia = false;
      });
      _checkDuplicate();
    } catch (_) {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  void _setDate(DateTime d) => setState(() => _date = d);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) _setDate(picked);
  }

  Future<void> _pickTime() async {
    TimeOfDay initial = TimeOfDay.now();
    final parts = _timeCtrl.text.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) initial = TimeOfDay(hour: h, minute: m);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      _timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickFile() async {
    final type = widget.channel == ArticleChannel.radio ? FileType.audio : FileType.video;
    final result = await FilePicker.platform.pickFiles(type: type, allowMultiple: false);
    if (result != null && result.files.isNotEmpty) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _scrapeUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan Link URL terlebih dahulu')));
      return;
    }
    setState(() => _scraping = true);
    try {
      final result = await _articleService.scrapeOnlineUrl(url);
      if (!mounted) return;
      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.error ?? 'Scrape gagal')));
        return;
      }
      setState(() {
        if (result.title != null) _titleCtrl.text = result.title!;
        if (result.content != null) _contentCtrl.text = result.content!;
        if (result.journalist != null) _journalistCtrl.text = result.journalist!;
        if (result.pages != null) _pagesCtrl.text = '${result.pages}';
        if (result.mmCol != null) _mmColCtrl.text = '${result.mmCol}';
        if (result.datee != null) {
          final d = DateTime.tryParse(result.datee!);
          if (d != null) _date = d;
        }
        if (result.mediaId != null) {
          _selectedMedia = _mediaOptions.where((m) => m.mediaId == result.mediaId).firstOrNull ?? _selectedMedia;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL berhasil di-scrape')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _scraping = false);
    }
  }

  Future<void> _pasteUrl() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) _urlCtrl.text = data!.text!.trim();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedMedia == null) return;

    setState(() => _submitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      String? filePath;

      if (_pickedFile != null && widget.channel != ArticleChannel.online) {
        final bytes = _pickedFile!.bytes;
        if (bytes == null) throw Exception('Tidak dapat membaca file');
        final upload = await _articleService.uploadMediaFile(
          channel: widget.channel,
          bytes: bytes,
          filename: _pickedFile!.name,
          mediaId: '${_selectedMedia!.mediaId}',
        );
        filePath = upload['dbPath'] as String?;
      }

      switch (widget.channel) {
        case ArticleChannel.tv:
          await _articleService.createTv(
            mediaId: _selectedMedia!.mediaId,
            title: _titleCtrl.text,
            datee: dateStr,
            content: _contentCtrl.text,
            journalist: _journalistCtrl.text,
            timee: _timeCtrl.text,
            duration: _durationCtrl.text,
            filee: filePath,
          );
          break;
        case ArticleChannel.radio:
          await _articleService.createRadio(
            mediaId: _selectedMedia!.mediaId,
            title: _titleCtrl.text,
            datee: dateStr,
            content: _contentCtrl.text,
            journalist: _journalistCtrl.text,
            timee: _timeCtrl.text,
            duration: _durationCtrl.text,
            filee: filePath,
          );
          break;
        case ArticleChannel.online:
          await _articleService.createOnline(
            mediaId: _selectedMedia!.mediaId,
            title: _titleCtrl.text,
            datee: dateStr,
            content: _contentCtrl.text,
            journalist: _journalistCtrl.text,
            url: _urlCtrl.text,
            pages: int.tryParse(_pagesCtrl.text),
            mmCol: double.tryParse(_mmColCtrl.text),
          );
          break;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Artikel ${widget.channel.label} berhasil diupload')));
      context.go(widget.channel.listRoute);
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
    return PageScaffold(
      title: widget.channel.uploadTitle,
      subtitle: 'Single upload',
      actions: [
        IconButton(
          icon: const Icon(Icons.library_add_outlined),
          tooltip: 'Multi Upload',
          onPressed: () => context.push(widget.channel.multiUploadRoute),
        ),
      ],
      body: _loadingMedia
          ? const LoadingView(message: 'Memuat daftar media', subtitle: 'Menyiapkan formulir upload…')
          : _mediaOptions.isEmpty
              ? const EmptyState(
                  icon: Icons.newspaper_outlined,
                  title: 'Tidak ada media',
                  subtitle: 'Tambahkan media terlebih dahulu.',
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PageHeader(
                      title: widget.channel.uploadTitle,
                      description: widget.channel == ArticleChannel.online
                          ? 'Fields: Media, Date, Link URL, Title, Content, Journalist, Pages, MM Column.'
                          : 'Fields: Media, Date, Time (WIB), Anchor/Journalist, Duration (seconds), Title, Content, File.',
                    ),
                    if (_duplicates.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      AlertBanner(
                        tone: AlertTone.warning,
                        icon: Icons.warning_amber_outlined,
                        title: 'Possible duplicate (${_duplicates.length})',
                        message: _duplicates.first.title,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          FormSection(
                            title: 'Media & Date',
                            child: Column(
                              children: [
                                DropdownButtonFormField<MediaModel>(
                                  value: _selectedMedia,
                                  decoration: const InputDecoration(labelText: 'Media *', prefixIcon: Icon(Icons.business_outlined)),
                                  items: _mediaOptions.map((m) => DropdownMenuItem(value: m, child: Text(m.mediaName, overflow: TextOverflow.ellipsis))).toList(),
                                  onChanged: (v) {
                                    setState(() => _selectedMedia = v);
                                    _checkDuplicate();
                                  },
                                  validator: (v) => v == null ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                InkWell(
                                  onTap: _pickDate,
                                  borderRadius: BorderRadius.circular(10),
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Date *', prefixIcon: Icon(Icons.calendar_today_outlined)),
                                    child: Text(DateFormat('dd/MM/yyyy').format(_date)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                DateShortcutRow(
                                  onToday: () => _setDate(DateTime.now()),
                                  onYesterday: () => _setDate(DateTime.now().subtract(const Duration(days: 1))),
                                ),
                              ],
                            ),
                          ),
                          if (widget.channel == ArticleChannel.online) ...[
                            const SizedBox(height: 16),
                            FormSection(
                              title: 'Link & Scrape',
                              subtitle: 'Sama seperti web — scrape URL untuk auto-fill field',
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _urlCtrl,
                                    decoration: InputDecoration(
                                      labelText: 'Link URL',
                                      hintText: 'https://example.com/article',
                                      prefixIcon: const Icon(Icons.link_outlined),
                                      suffixIcon: IconButton(icon: const Icon(Icons.content_paste_outlined), onPressed: _pasteUrl, tooltip: 'Paste'),
                                    ),
                                    keyboardType: TextInputType.url,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _scraping ? null : _scrapeUrl,
                                      icon: _scraping
                                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                          : const Icon(Icons.auto_fix_high_outlined),
                                      label: Text(_scraping ? 'Scraping…' : 'Scrape URL'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.channel != ArticleChannel.online) ...[
                            const SizedBox(height: 16),
                            FormSection(
                              title: 'Broadcast Details',
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _timeCtrl,
                                    readOnly: true,
                                    onTap: _pickTime,
                                    decoration: const InputDecoration(
                                      labelText: 'Time (WIB)',
                                      hintText: 'HH:MM — 24 jam UTC+7',
                                      prefixIcon: Icon(Icons.schedule_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _journalistCtrl,
                                    decoration: const InputDecoration(labelText: 'Anchor / Journalist', prefixIcon: Icon(Icons.person_outline)),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _durationCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Duration (seconds)',
                                      hintText: 'e.g. 180',
                                      prefixIcon: Icon(Icons.timer_outlined),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                  const SizedBox(height: 14),
                                  OutlinedButton.icon(
                                    onPressed: _pickFile,
                                    icon: const Icon(Icons.attach_file_outlined),
                                    label: Text(_pickedFile?.name ?? 'Attach video/audio file (optional)'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (widget.channel == ArticleChannel.online) ...[
                            const SizedBox(height: 16),
                            FormSection(
                              title: 'Publication',
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _journalistCtrl,
                                    decoration: const InputDecoration(labelText: 'Journalist', prefixIcon: Icon(Icons.person_outline)),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _pagesCtrl,
                                          decoration: const InputDecoration(labelText: 'Pages', prefixIcon: Icon(Icons.description_outlined)),
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _mmColCtrl,
                                          decoration: const InputDecoration(labelText: 'MM Column', prefixIcon: Icon(Icons.straighten_outlined)),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          FormSection(
                            title: 'Article Content',
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _titleCtrl,
                                  decoration: const InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title_outlined)),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _contentCtrl,
                                  decoration: const InputDecoration(
                                    labelText: 'Content',
                                    prefixIcon: Icon(Icons.notes_outlined),
                                    alignLabelWithHint: true,
                                  ),
                                  maxLines: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                                  : const Icon(Icons.cloud_upload_outlined),
                              label: Text(_submitting ? 'Uploading…' : 'Upload Artikel'),
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
