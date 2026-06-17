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

class ArticleEditScreen extends StatefulWidget {
  const ArticleEditScreen({super.key, required this.channel, required this.article});

  final ArticleChannel channel;
  final ArticleModel article;

  @override
  State<ArticleEditScreen> createState() => _ArticleEditScreenState();
}

class _ArticleEditScreenState extends State<ArticleEditScreen> {
  late final ArticleService _articleService;
  late final MediaService _mediaService;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _journalistCtrl;
  late final TextEditingController _timeCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _pagesCtrl;
  late final TextEditingController _mmColCtrl;

  List<MediaModel> _mediaOptions = [];
  MediaModel? _selectedMedia;
  late DateTime _date;
  bool _loadingMedia = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final a = widget.article;
    _articleService = ArticleService(context.read<AuthProvider>().api);
    _mediaService = MediaService(context.read<AuthProvider>().api);
    _titleCtrl = TextEditingController(text: a.title);
    _contentCtrl = TextEditingController(text: a.content ?? '');
    _journalistCtrl = TextEditingController(text: a.journalist ?? '');
    _timeCtrl = TextEditingController(text: a.timee ?? '');
    _durationCtrl = TextEditingController(text: a.duration ?? '');
    _urlCtrl = TextEditingController(text: a.url ?? '');
    _pagesCtrl = TextEditingController(text: a.pages?.toString() ?? '');
    _mmColCtrl = TextEditingController(text: a.mmCol?.toString() ?? '');
    _date = DateTime.tryParse(a.datee ?? '') ?? DateTime.now();
    _loadMedia();
  }

  @override
  void dispose() {
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

  Future<void> _loadMedia() async {
    final typeId = widget.channel.mediaTypeId;
    if (typeId == null) return;
    try {
      final list = await _mediaService.listByType(typeId);
      if (!mounted) return;
      setState(() {
        _mediaOptions = list;
        _selectedMedia = list.where((m) => m.mediaId == widget.article.mediaId).firstOrNull ?? (list.isNotEmpty ? list.first : null);
        _loadingMedia = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMedia = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedMedia == null) return;
    setState(() => _submitting = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_date);
      final body = <String, dynamic>{
        'media_id': _selectedMedia!.mediaId,
        'title': _titleCtrl.text.trim(),
        'datee': dateStr,
        'content': _contentCtrl.text.trim().isEmpty ? null : _contentCtrl.text.trim(),
        'journalist': _journalistCtrl.text.trim().isEmpty ? null : _journalistCtrl.text.trim(),
      };
      if (widget.channel != ArticleChannel.online) {
        body['timee'] = _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim();
        body['duration'] = _durationCtrl.text.trim().isEmpty ? null : _durationCtrl.text.trim();
      } else {
        body['url'] = _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim();
        body['pages'] = int.tryParse(_pagesCtrl.text.trim());
        body['mm_col'] = double.tryParse(_mmColCtrl.text.trim());
      }
      await _articleService.updateArticle(widget.channel, widget.article.articleId, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artikel berhasil diperbarui')));
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      title: 'Edit ${widget.channel.label}',
      subtitle: '#${widget.article.articleId}',
      body: _loadingMedia
          ? const LoadingView(message: 'Memuat daftar media', subtitle: 'Menyiapkan formulir edit…')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      FormSection(
                        title: 'Media & Date',
                        child: Column(
                          children: [
                            DropdownButtonFormField<MediaModel>(
                              initialValue: _selectedMedia,
                              decoration: const InputDecoration(labelText: 'Media *', prefixIcon: Icon(Icons.business_outlined)),
                              items: _mediaOptions.map((m) => DropdownMenuItem(value: m, child: Text(m.mediaName, overflow: TextOverflow.ellipsis))).toList(),
                              onChanged: (v) => setState(() => _selectedMedia = v),
                              validator: (v) => v == null ? 'Required' : null,
                            ),
                            const SizedBox(height: 14),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.calendar_today_outlined, color: AppColors.navy),
                              title: Text(DateFormat('dd/MM/yyyy').format(_date)),
                              trailing: const Icon(Icons.edit_outlined, color: AppColors.navy),
                              onTap: () async {
                                final p = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime.now());
                                if (p != null) setState(() => _date = p);
                              },
                            ),
                          ],
                        ),
                      ),
                      if (widget.channel == ArticleChannel.online) ...[
                        const SizedBox(height: 16),
                        FormSection(
                          title: 'Online Fields',
                          child: Column(
                            children: [
                              TextFormField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Link URL', prefixIcon: Icon(Icons.link_outlined))),
                              const SizedBox(height: 14),
                              TextFormField(controller: _journalistCtrl, decoration: const InputDecoration(labelText: 'Journalist', prefixIcon: Icon(Icons.person_outline))),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(child: TextFormField(controller: _pagesCtrl, decoration: const InputDecoration(labelText: 'Pages', prefixIcon: Icon(Icons.description_outlined)), keyboardType: TextInputType.number)),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: _mmColCtrl, decoration: const InputDecoration(labelText: 'MM Column', prefixIcon: Icon(Icons.straighten_outlined)), keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                              ]),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        FormSection(
                          title: 'Broadcast Details',
                          child: Column(
                            children: [
                              TextFormField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Time (WIB)', prefixIcon: Icon(Icons.schedule_outlined))),
                              const SizedBox(height: 14),
                              TextFormField(controller: _journalistCtrl, decoration: const InputDecoration(labelText: 'Anchor / Journalist', prefixIcon: Icon(Icons.person_outline))),
                              const SizedBox(height: 14),
                              TextFormField(controller: _durationCtrl, decoration: const InputDecoration(labelText: 'Duration (seconds)', prefixIcon: Icon(Icons.timer_outlined)), keyboardType: TextInputType.number),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      FormSection(
                        title: 'Article Content',
                        child: Column(
                          children: [
                            TextFormField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Title *', prefixIcon: Icon(Icons.title_outlined)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
                            const SizedBox(height: 14),
                            TextFormField(controller: _contentCtrl, decoration: const InputDecoration(labelText: 'Content', prefixIcon: Icon(Icons.notes_outlined), alignLabelWithHint: true), maxLines: 6),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white)) : const Icon(Icons.save_outlined),
                          label: Text(_submitting ? 'Saving…' : 'Save Changes'),
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
