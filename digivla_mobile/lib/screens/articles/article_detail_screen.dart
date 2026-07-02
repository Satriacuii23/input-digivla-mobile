import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../config/theme.dart';
import '../../core/auth/auth_provider.dart';
import '../../models/article.dart';
import '../../services/article_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/digivla_widgets.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({super.key, required this.channel, required this.article});

  final ArticleChannel channel;
  final ArticleModel article;

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final ArticleService _service;
  bool _deleting = false;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _service = ArticleService(context.read<AuthProvider>().api);
    if (widget.channel == ArticleChannel.tv && widget.article.filee != null && widget.article.filee!.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.article.filee!))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Hapus artikel "${widget.article.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await _service.deleteArticle(widget.channel, widget.article.articleId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Artikel dihapus')));
      context.go(widget.channel.listRoute);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('ApiException: ', ''))));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final article = widget.article;
    final channel = widget.channel;
    final user = context.watch<AuthProvider>().user;
    final canEdit = user?.canWriteChannel(channel.apiPath) ?? false;
    final canDelete = user?.canDeleteArticles ?? false;

    return PageScaffold(
      title: 'Preview ${channel.label}',
      subtitle: 'ID ${article.articleId}',
      actions: [
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () => context.push('/${channel.apiPath}/edit/${article.articleId}', extra: article),
          ),
        if (canDelete)
          IconButton(
            icon: _deleting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: _deleting ? null : _delete,
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [ChannelBadge(label: channel.label), const Spacer(), Text('#${article.articleId}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted))]),
                const SizedBox(height: 14),
                Text(article.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.navy, height: 1.35)),
              ],
            ),
          ),
          if (_videoController != null && _videoController!.value.isInitialized) ...[
            const SizedBox(height: 16),
            DigivlaCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                  VideoProgressIndicator(_videoController!, allowScrubbing: true),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(_videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          DigivlaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Publication Info'),
                const SizedBox(height: 8),
                InfoRow(icon: Icons.business_outlined, label: 'Media', value: article.mediaName ?? 'ID ${article.mediaId}'),
                InfoRow(icon: Icons.calendar_today_outlined, label: 'Date', value: article.datee ?? '—'),
                if (article.journalist != null) InfoRow(icon: Icons.person_outline, label: 'Journalist', value: article.journalist!),
                if (article.timee != null) InfoRow(icon: Icons.schedule_outlined, label: 'Time', value: article.timee!),
                if (article.duration != null) InfoRow(icon: Icons.timer_outlined, label: 'Duration', value: article.duration!),
                if (article.url != null) InfoRow(icon: Icons.link_outlined, label: 'URL', value: article.url!),
                if (article.pages != null) InfoRow(icon: Icons.description_outlined, label: 'Pages', value: '${article.pages}'),
                if (article.mmCol != null) InfoRow(icon: Icons.straighten_outlined, label: 'MM Column', value: '${article.mmCol}'),
                if (article.filee != null && article.filee!.isNotEmpty) InfoRow(icon: Icons.videocam_outlined, label: 'File', value: article.filee!),
                if (article.createdAt != null) InfoRow(icon: Icons.access_time_outlined, label: 'Created', value: article.createdAt!),
              ],
            ),
          ),
          if (article.content != null && article.content!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            DigivlaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Content'),
                  const SizedBox(height: 8),
                  Text(article.content!, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.55)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
