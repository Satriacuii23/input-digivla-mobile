import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/media.dart';
import '../../services/media_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class MediaDetailScreen extends StatefulWidget {
  const MediaDetailScreen({super.key, required this.media});

  final MediaModel media;

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late final MediaService _service;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _service = MediaService(context.read<AuthProvider>().api);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media'),
        content: Text('Hapus media "${widget.media.mediaName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteMedia(widget.media.mediaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media dihapus')));
      context.go('/media');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.media;
    final isAdmin = context.watch<AuthProvider>().user?.canManageMedia ?? false;

    return PageScaffold(
      title: 'Preview Media',
      subtitle: media.mediaName,
      actions: [
        if (isAdmin) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/media/edit/${media.mediaId}', extra: media),
          ),
          IconButton(
            icon: _deleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _deleting ? null : _delete,
          ),
        ],
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(media.mediaName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1.25)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (media.typeDisplay != null) ChannelBadge(label: media.typeDisplay!),
                    if (media.status != null) StatusPill(label: media.status!, active: media.status == 'Active'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Information'),
                const SizedBox(height: 8),
                InfoRow(icon: Icons.tag_outlined, label: 'Media ID', value: '${media.mediaId}'),
                InfoRow(icon: Icons.category_outlined, label: 'Type', value: media.typeName ?? '${media.mediaType}'),
                InfoRow(icon: Icons.toggle_on_outlined, label: 'Status', value: media.status ?? '—'),
                InfoRow(icon: Icons.language_outlined, label: 'Language', value: media.language ?? '—'),
                if (media.tier != null) InfoRow(icon: Icons.star_outline, label: 'Tier', value: media.tier!),
                if (media.circulation != null) InfoRow(icon: Icons.groups_outlined, label: 'Circulation', value: '${media.circulation}'),
                if (media.rateBw != null) InfoRow(icon: Icons.payments_outlined, label: 'Rate BW', value: '${media.rateBw}'),
                if (media.rateFc != null) InfoRow(icon: Icons.payments_outlined, label: 'Rate FC', value: '${media.rateFc}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
