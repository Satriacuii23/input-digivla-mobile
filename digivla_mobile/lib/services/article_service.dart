import '../core/api/api_client.dart';
import '../models/article.dart';

class ArticleService {
  ArticleService(this._api);

  final ApiClient _api;

  Future<PaginatedResult<ArticleModel>> listArticles({
    required ArticleChannel channel,
    int page = 1,
    int limit = 15,
    String? search,
    int? mediaId,
    String? createdStartDate,
    String? createdEndDate,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (mediaId != null) query['media_id'] = '$mediaId';
    if (createdStartDate != null) query['created_start_date'] = createdStartDate;
    if (createdEndDate != null) query['created_end_date'] = createdEndDate;

    final data = await _api.getJson('/articles/${channel.apiPath}', query: query);
    final items = (data['data'] as List<dynamic>? ?? [])
        .map((e) => ArticleModel.fromJson(e as Map<String, dynamic>, channel))
        .toList();
    final pagination = PaginationModel.fromJson(data['pagination'] as Map<String, dynamic>?);
    return PaginatedResult(data: items, pagination: pagination);
  }

  Future<ArticleModel> getArticle(ArticleChannel channel, int articleId) async {
    final data = await _api.getJson('/articles/${channel.apiPath}/$articleId');
    return ArticleModel.fromJson(data, channel);
  }

  Future<ArticleModel> createTv({
    required int mediaId,
    required String title,
    required String datee,
    String? content,
    String? journalist,
    String? timee,
    String? duration,
    String? filee,
  }) =>
      _create(ArticleChannel.tv, {
        'media_id': mediaId,
        'title': title.trim(),
        'datee': datee,
        if (content != null && content.isNotEmpty) 'content': content.trim(),
        if (journalist != null && journalist.isNotEmpty) 'journalist': journalist.trim(),
        if (timee != null && timee.isNotEmpty) 'timee': timee,
        if (duration != null && duration.isNotEmpty) 'duration': duration,
        if (filee != null && filee.isNotEmpty) 'filee': filee,
      });

  Future<ArticleModel> createRadio({
    required int mediaId,
    required String title,
    required String datee,
    String? content,
    String? journalist,
    String? timee,
    String? duration,
    String? filee,
  }) =>
      _create(ArticleChannel.radio, {
        'media_id': mediaId,
        'title': title.trim(),
        'datee': datee,
        if (content != null && content.isNotEmpty) 'content': content.trim(),
        if (journalist != null && journalist.isNotEmpty) 'journalist': journalist.trim(),
        if (timee != null && timee.isNotEmpty) 'timee': timee,
        if (duration != null && duration.isNotEmpty) 'duration': duration,
        if (filee != null && filee.isNotEmpty) 'filee': filee,
      });

  Future<ArticleModel> createOnline({
    required int mediaId,
    required String title,
    required String datee,
    String? content,
    String? journalist,
    String? url,
    int? pages,
    double? mmCol,
  }) =>
      _create(ArticleChannel.online, {
        'media_id': mediaId,
        'title': title.trim(),
        'datee': datee,
        if (content != null && content.isNotEmpty) 'content': content.trim(),
        if (journalist != null && journalist.isNotEmpty) 'journalist': journalist.trim(),
        if (url != null && url.isNotEmpty) 'url': url.trim(),
        if (pages != null) 'pages': pages,
        if (mmCol != null) 'mm_col': mmCol,
      });

  Future<Map<String, dynamic>> uploadMediaFile({
    required ArticleChannel channel,
    required List<int> bytes,
    required String filename,
    required String mediaId,
  }) async {
    if (channel == ArticleChannel.online) {
      throw UnsupportedError('Online articles do not use file upload');
    }
    final path = channel == ArticleChannel.tv ? '/upload/tv' : '/upload/radio';
    final mediaTypeId = channel == ArticleChannel.tv ? '012' : '013';
    return _api.uploadMultipart(
      path,
      fileField: 'file',
      bytes: bytes,
      filename: filename,
      fields: {
        'mediaId': mediaId.padLeft(4, '0'),
        'mediaTypeId': mediaTypeId,
      },
    );
  }

  Future<ArticleModel> _create(ArticleChannel channel, Map<String, dynamic> body) async {
    final data = await _api.postJson('/articles/${channel.apiPath}', body);
    return ArticleModel.fromJson(data, channel);
  }

  Future<ArticleModel> updateArticle(ArticleChannel channel, int articleId, Map<String, dynamic> body) async {
    final data = await _api.putJson('/articles/${channel.apiPath}/$articleId', body);
    return ArticleModel.fromJson(data, channel);
  }

  Future<void> deleteArticle(ArticleChannel channel, int articleId) async {
    await _api.deleteJson('/articles/${channel.apiPath}/$articleId');
  }

  /// Scrape multiple online URLs — same as web multi upload scrape drawer.
  Future<List<OnlineScrapeResult>> scrapeOnlineUrls(List<String> urls) async {
    final cleaned = urls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
    if (cleaned.isEmpty) return [];
    final data = await _api.postJson('/articles/online/scrape-urls', {'urls': cleaned});
    final results = data['results'] as List<dynamic>? ?? [];
    return results.map((e) => OnlineScrapeResult.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Check duplicate article — same as web upload duplicate warning.
  Future<List<DuplicateArticle>> checkDuplicate({
    required ArticleChannel channel,
    String? title,
    String? content,
    int? mediaId,
  }) async {
    final query = <String, String>{};
    if (title != null && title.trim().isNotEmpty) query['title'] = title.trim();
    if (content != null && content.trim().isNotEmpty) query['content'] = content.trim();
    if (mediaId != null) query['media_id'] = '$mediaId';

    if (query.isEmpty) return [];

    final data = await _api.getJson('/articles/${channel.apiPath}/check-duplicate', query: query);
    if (data['exists'] != true) return [];
    final list = data['duplicates'] as List<dynamic>? ?? [];
    return list.map((e) => DuplicateArticle.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Scrape online article URL — same as web Multi Upload scrape.
  Future<OnlineScrapeResult> scrapeOnlineUrl(String url) async {
    final data = await _api.postJson('/articles/online/scrape-urls', {'urls': [url.trim()]});
    final results = data['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) throw Exception('Scrape tidak mengembalikan hasil');
    final item = results.first as Map<String, dynamic>;
    return OnlineScrapeResult.fromJson(item);
  }
}

class DuplicateArticle {
  const DuplicateArticle({
    required this.articleId,
    required this.title,
    this.contentPreview,
    this.datee,
    this.mediaName,
    this.createdAt,
  });

  final int articleId;
  final String title;
  final String? contentPreview;
  final String? datee;
  final String? mediaName;
  final String? createdAt;

  factory DuplicateArticle.fromJson(Map<String, dynamic> json) {
    return DuplicateArticle(
      articleId: json['article_id'] as int,
      title: json['title'] as String? ?? '',
      contentPreview: json['content_preview'] as String?,
      datee: json['datee']?.toString(),
      mediaName: json['media_name'] as String?,
      createdAt: json['created_at']?.toString(),
    );
  }
}

class OnlineScrapeResult {
  const OnlineScrapeResult({
    required this.success,
    this.error,
    this.title,
    this.content,
    this.journalist,
    this.datee,
    this.mediaId,
    this.mediaName,
    this.pages,
    this.mmCol,
    this.url,
  });

  final bool success;
  final String? error;
  final String? title;
  final String? content;
  final String? journalist;
  final String? datee;
  final int? mediaId;
  final String? mediaName;
  final int? pages;
  final double? mmCol;
  final String? url;

  factory OnlineScrapeResult.fromJson(Map<String, dynamic> json) {
    return OnlineScrapeResult(
      success: json['success'] == true,
      error: json['error'] as String?,
      title: json['title'] as String?,
      content: json['content'] as String?,
      journalist: json['journalist'] as String?,
      datee: json['datee']?.toString(),
      mediaId: json['media_id'] as int?,
      mediaName: json['media_name'] as String?,
      pages: json['pages'] as int?,
      mmCol: (json['mm_col'] as num?)?.toDouble(),
      url: json['url'] as String?,
    );
  }
}
