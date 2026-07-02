import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/media.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';
import '../../widgets/list_filters.dart';

class MediaListScreen extends StatefulWidget {
  const MediaListScreen({super.key});

  @override
  State<MediaListScreen> createState() => _MediaListScreenState();
}

class _MediaListScreenState extends State<MediaListScreen> {
  late final MediaService _service;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<MediaModel> _items = [];
  int _page = 1;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int? _filterTypeId;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _service = MediaService(context.read<AuthProvider>().api);
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
      final result = await _service.listMedia(
        page: _page,
        limit: 20,
        mediaTypeId: _filterTypeId,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        status: _filterStatus,
      );
      if (!mounted) return;
      setState(() {
        _items = result.items;
        _page = result.page;
        _totalPages = result.totalPages;
        _total = result.total;
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
    if (_loadingMore || _page >= _totalPages) return;
    setState(() => _loadingMore = true);
    try {
      final result = await _service.listMedia(
        page: _page + 1,
        limit: 20,
        mediaTypeId: _filterTypeId,
        search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
        status: _filterStatus,
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...result.items];
        _page = result.page;
        _totalPages = result.totalPages;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.canManageMedia ?? false;

    return TabPageScaffold(
      title: 'List Media',
      subtitle: '$_total media',
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/media/add');
                _load(refresh: true);
              },
              backgroundColor: AppColors.navy,
              icon: const Icon(Icons.add, color: AppColors.white),
              label: const Text('Add Media', style: TextStyle(color: AppColors.white)),
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
                  decoration: InputDecoration(
                    hintText: 'Cari nama media…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.close), onPressed: () {
                            _searchCtrl.clear();
                            _load(refresh: true);
                          })
                        : null,
                  ),
                  onSubmitted: (_) => _load(refresh: true),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Status', isDense: true, prefixIcon: Icon(Icons.check_circle_outline, size: 18), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                        items: const [
                          DropdownMenuItem(value: 'Active', child: Text('Active', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'Inactive', child: Text('Inactive', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 'All', child: Text('Semua', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          setState(() => _filterStatus = v ?? 'Active');
                          _load(refresh: true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _filterTypeId,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Media Type', isDense: true, prefixIcon: Icon(Icons.category_outlined, size: 18), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Semua', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 12, child: Text('TV', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 13, child: Text('Radio', style: TextStyle(fontSize: 13))),
                          DropdownMenuItem(value: 4, child: Text('Online', style: TextStyle(fontSize: 13))),
                        ],
                        onChanged: (v) {
                          setState(() => _filterTypeId = v);
                          _load(refresh: true);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView(message: 'Memuat media', subtitle: 'Mengambil data dari server…')
                : _error != null
                    ? EmptyState(icon: Icons.error_outline, title: 'Gagal memuat', subtitle: _error)
                    : _items.isEmpty
                        ? const EmptyState(icon: Icons.newspaper_outlined, title: 'Tidak ada media', subtitle: 'Coba ubah filter atau kata kunci pencarian.')
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
                                  return const LoadingMoreRow(message: 'Memuat media…');
                                }
                                final m = _items[index];
                                return DigivlaCard(
                                  onTap: () => context.push('/media/preview/${m.mediaId}', extra: m),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m.mediaName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.navy)),
                                            const SizedBox(height: 6),
                                            Text('ID ${m.mediaId} · ${m.typeDisplay ?? m.typeName ?? 'Type ${m.mediaType}'}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                            const SizedBox(height: 8),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 6,
                                              children: [
                                                if (m.status != null) StatusPill(label: m.status!, active: m.status == 'Active'),
                                                if (m.tier != null && m.tier!.isNotEmpty) MetaChip(icon: Icons.star_outline, label: m.tier!),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right, color: AppColors.textMuted),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.white,
        checkmarkColor: AppColors.navy,
        labelStyle: TextStyle(color: selected ? AppColors.navy : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 12),
        side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
        backgroundColor: AppColors.white,
      ),
    );
  }
}
