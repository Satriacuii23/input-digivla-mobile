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

/// Quality Control — uploads by created date, aligned with web QC pages.
class ArticleQcScreen extends StatefulWidget {
  const ArticleQcScreen({super.key, required this.channel});

  final ArticleChannel channel;

  @override
  State<ArticleQcScreen> createState() => _ArticleQcScreenState();
}

class _ArticleQcScreenState extends State<ArticleQcScreen> {
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
  QcPeriod _period = QcPeriod.todayYesterday;
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

  Future<void> _loadMediaOptions() async {
    final typeId = widget.channel.mediaTypeId;
    if (typeId == null) return;
    try {
      final list = await _mediaService.listByType(typeId);
      if (mounted) setState(() => _mediaOptions = list);
    } catch (_) {}
  }

  ({String start, String end}) get _dateRange => QcPeriodFilterRow.dateRange(_period);

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final range = _dateRange;
      final result = await _service.listArticles(
        channel: widget.channel,
        page: 1,
        createdStartDate: range.start,
        createdEndDate: range.end,
        mediaId: _mediaFilterId,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
      final range = _dateRange;
      final result = await _service.listArticles(
        channel: widget.channel,
        page: _page + 1,
        createdStartDate: range.start,
        createdEndDate: range.end,
        mediaId: _mediaFilterId,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final range = _dateRange;
    return PageScaffold(
      title: 'QC ${widget.channel.label}',
      subtitle: '${range.start} → ${range.end} · $_total articles',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              children: [
                QcPeriodFilterRow(
                  period: _period,
                  onChanged: (p) {
                    setState(() => _period = p);
                    _load(refresh: true);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search title or content…',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _load(refresh: true),
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
                ? const LoadingView(message: 'Loading QC', subtitle: 'Fetching uploads…')
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: 'Load failed', subtitle: _error)
                    : _items.isEmpty
                        ? EmptyState(
                            icon: Icons.fact_check_outlined,
                            title: 'No articles',
                            subtitle: 'No ${widget.channel.label} uploads in this period.',
                          )
                        : RefreshIndicator(
                            onRefresh: () => _load(refresh: true),
                            color: AppColors.navy,
                            child: ListView.separated(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _items.length + (_loadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                if (index >= _items.length) {
                                  return const LoadingMoreRow(message: 'Loading…');
                                }
                                final a = _items[index];
                                return DigivlaCard(
                                  onTap: () => context.push(
                                    '/${widget.channel.apiPath}/preview/${a.articleId}',
                                    extra: a,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ChannelBadge(label: 'QC ${widget.channel.label}'),
                                          const Spacer(),
                                          TextButton.icon(
                                            onPressed: () => context.push(
                                              '/${widget.channel.apiPath}/edit/${a.articleId}',
                                              extra: a,
                                            ),
                                            icon: const Icon(Icons.edit_outlined, size: 16),
                                            label: const Text('Edit', style: TextStyle(fontSize: 12)),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        a.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        a.contentPreview,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          if (a.mediaName != null) MetaChip(icon: Icons.business_outlined, label: a.mediaName!),
                                          if (a.datee != null) MetaChip(icon: Icons.calendar_today_outlined, label: a.datee!),
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
