enum ArticleChannel { tv, radio, online }

extension ArticleChannelX on ArticleChannel {
  String get label {
    switch (this) {
      case ArticleChannel.tv:
        return 'TV';
      case ArticleChannel.radio:
        return 'Radio';
      case ArticleChannel.online:
        return 'Online';
    }
  }

  String get apiPath {
    switch (this) {
      case ArticleChannel.tv:
        return 'tv';
      case ArticleChannel.radio:
        return 'radio';
      case ArticleChannel.online:
        return 'online';
    }
  }

  int? get mediaTypeId {
    switch (this) {
      case ArticleChannel.tv:
        return 12;
      case ArticleChannel.radio:
        return 13;
      case ArticleChannel.online:
        return 4;
    }
  }

  String get listTitle => 'List Articles $label';

  String get uploadTitle => 'Upload $label';

  String get uploadRoute => '/$apiPath/upload';

  String get multiUploadRoute => '/$apiPath/upload/multi';

  String get listRoute => '/$apiPath';
}

class ArticleModel {
  final int articleId;
  final int mediaId;
  final String title;
  final String? content;
  final String? datee;
  final String? journalist;
  final String? mediaName;
  final String? createdAt;
  final String? timee;
  final String? duration;
  final String? filee;
  final String? url;
  final int? pages;
  final double? mmCol;

  const ArticleModel({
    required this.articleId,
    required this.mediaId,
    required this.title,
    this.content,
    this.datee,
    this.journalist,
    this.mediaName,
    this.createdAt,
    this.timee,
    this.duration,
    this.filee,
    this.url,
    this.pages,
    this.mmCol,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json, ArticleChannel channel) {
    return ArticleModel(
      articleId: json['article_id'] as int,
      mediaId: json['media_id'] as int,
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      datee: json['datee']?.toString(),
      journalist: json['journalist'] as String?,
      mediaName: json['media_name'] as String?,
      createdAt: json['created_at']?.toString() ?? json['createAt']?.toString(),
      timee: json['timee'] as String?,
      duration: json['duration'] as String?,
      filee: json['filee'] as String?,
      url: json['url'] as String?,
      pages: json['pages'] as int?,
      mmCol: json['mm_col'] is num ? (json['mm_col'] as num).toDouble() : null,
    );
  }

  String get contentPreview {
    final c = content?.trim() ?? '';
    if (c.isEmpty) return '—';
    return c.length > 120 ? '${c.substring(0, 120)}…' : c;
  }
}

class PaginationModel {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  const PaginationModel({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PaginationModel(page: 1, limit: 10, total: 0, totalPages: 1);
    }
    return PaginationModel(
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      total: json['total'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  bool get hasMore => page < totalPages;
}

class PaginatedResult<T> {
  final List<T> data;
  final PaginationModel pagination;

  const PaginatedResult({required this.data, required this.pagination});
}
