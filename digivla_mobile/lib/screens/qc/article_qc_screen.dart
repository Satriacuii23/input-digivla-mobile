import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/article.dart';
import '../../services/article_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

/// Quality Control — artikel upload hari ini per channel.
class ArticleQcScreen extends StatefulWidget {
  const ArticleQcScreen({super.key, required this.channel});

  final ArticleChannel channel;

  @override
  State<ArticleQcScreen> createState() => _ArticleQcScreenState();
}

class _ArticleQcScreenState extends State<ArticleQcScreen> {
  late final ArticleService _service;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<ArticleModel> _items = [];
  int _page = 1;
  bool _hasMore = true;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String get _today =>
      '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _service = ArticleService(context.read<AuthProvider>().api);
    _scrollCtrl.addListener(_onScroll);
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

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
      });
    }
    try {
      final result = await _service.listArticles(
        channel: widget.channel,
        page: 1,
        createdStartDate: _today,
        createdEndDate: _today,
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
      final result = await _service.listArticles(
        channel: widget.channel,
        page: _page + 1,
        createdStartDate: _today,
        createdEndDate: _today,
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
    return PageScaffold(
      title: 'QC ${widget.channel.label}',
      subtitle: "Today's uploads · $_today · $_total articles",
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari judul atau konten…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onSubmitted: (_) => _load(refresh: true),
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Memuat QC', subtitle: 'Artikel upload hari ini…')
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: 'Gagal memuat', subtitle: _error)
                    : _items.isEmpty
                        ? EmptyState(
                            icon: Icons.fact_check_outlined,
                            title: 'Tidak ada artikel',
                            subtitle: 'Belum ada upload ${widget.channel.label} hari ini.',
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
                                  return const LoadingMoreRow(message: 'Memuat…');
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
                                          Text('#${a.articleId}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
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
