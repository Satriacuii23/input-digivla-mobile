import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/article.dart';
import '../../models/media.dart';
import '../../services/article_service.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';
import '../../widgets/list_filters.dart';

class ArticleListScreen extends StatefulWidget {
  const ArticleListScreen({super.key, required this.channel});

  final ArticleChannel channel;

  @override
  State<ArticleListScreen> createState() => _ArticleListScreenState();
}

class _ArticleListScreenState extends State<ArticleListScreen> {
  late final ArticleService _service;
  late final MediaService _mediaService;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ArticleModel> _items = [];
  List<MediaModel> _mediaOptions = [];
  int _page = 1;
  bool _hasMore = true;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  final _dateFilter = ArticleDateFilterState();
  int? _mediaFilterId;

  @override
  void initState() {
    super.initState();
    _service = ArticleService(context.read<AuthProvider>().api);
    _mediaService = MediaService(context.read<AuthProvider>().api);
    _scrollCtrl.addListener(_onScroll);
    _loadMediaOptions();
    _load(refresh: true);
  }

  Future<void> _loadMediaOptions() async {
    final typeId = widget.channel.mediaTypeId;
    if (typeId == null) return;
    try {
      final list = await _mediaService.listByType(typeId);
      if (mounted) setState(() => _mediaOptions = list);
    } catch (_) {}
  }

  Map<String, String?> get _queryDates {
    final r = _dateFilter.apiRange;
    return {'start': r.start, 'end': r.end};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final dates = _queryDates;
      final result = await _service.listArticles(
        channel: widget.channel,
        page: 1,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        mediaId: _mediaFilterId,
        startDate: dates['start'],
        endDate: dates['end'],
      );
      if (!mounted) return;
      setState(() {
        _items = result.data;
        _page = result.pagination.page;
        _hasMore = result.pagination.hasMore;
        _total = result.pagination.total;
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

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final dates = _queryDates;
      final result = await _service.listArticles(
        channel: widget.channel,
        page: _page + 1,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        mediaId: _mediaFilterId,
        startDate: dates['start'],
        endDate: dates['end'],
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.data];
        _page = result.pagination.page;
        _hasMore = result.pagination.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _showUploadMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_outlined, color: AppColors.navy),
              title: Text(widget.channel.uploadTitle),
              subtitle: const Text('Single article upload'),
              onTap: () { Navigator.pop(ctx); context.push(widget.channel.uploadRoute); },
            ),
            ListTile(
              leading: const Icon(Icons.library_add_outlined, color: AppColors.navy),
              title: Text('Multi Upload ${widget.channel.label}'),
              subtitle: Text(widget.channel == ArticleChannel.online ? 'Scrape URLs + batch upload' : 'Upload multiple articles'),
              onTap: () { Navigator.pop(ctx); context.push(widget.channel.multiUploadRoute); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final canUpload = user?.canWriteChannel(widget.channel.apiPath) ?? false;

    return TabPageScaffold(
      title: widget.channel.listTitle,
      subtitle: '$_total articles · ${_dateFilter.label}',
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: _showUploadMenu,
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.upload_outlined, color: AppColors.white),
              label: Text(widget.channel.uploadTitle, style: const TextStyle(color: AppColors.white)),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(hintText: 'Search title or content…', prefixIcon: Icon(Icons.search), isDense: true),
                  onSubmitted: (_) => _load(refresh: true),
                ),
                const SizedBox(height: 10),
                ArticleDateFilterRow(
                  state: _dateFilter,
                  onChanged: (p) {
                    setState(() => _dateFilter.preset = p);
                    _load(refresh: true);
                  },
                ),
                if (_mediaOptions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  MediaFilterDropdown(
                    options: _mediaOptions,
                    selectedId: _mediaFilterId,
                    onChanged: (v) {
                      setState(() => _mediaFilterId = v);
                      _load(refresh: true);
                    },
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Memuat artikel', subtitle: 'Mengambil data dari server…')
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: 'Gagal memuat', subtitle: _error)
                    : _items.isEmpty
                        ? EmptyState(icon: Icons.article_outlined, title: 'Belum ada artikel', subtitle: 'Upload artikel ${widget.channel.label} pertama Anda.')
                        : RefreshIndicator(
                            onRefresh: () => _load(refresh: true),
                            color: AppColors.navy,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return const LoadingMoreRow(message: 'Memuat artikel…');
                                }
                                final a = _items[index];
                                return DigivlaCard(
                                  onTap: () => context.push('/${widget.channel.apiPath}/preview/${a.articleId}', extra: a),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ChannelBadge(label: widget.channel.label),
                                          const Spacer(),
                                          Text('#${a.articleId}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(a.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.35)),
                                      const SizedBox(height: 8),
                                      Text(a.contentPreview, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          MetaChip(icon: Icons.business_outlined, label: a.mediaName ?? 'Media ${a.mediaId}'),
                                          if (a.datee != null) MetaChip(icon: Icons.calendar_today_outlined, label: a.datee!),
                                          if (a.journalist != null && a.journalist!.isNotEmpty) MetaChip(icon: Icons.person_outline, label: a.journalist!),
                                        ],
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
