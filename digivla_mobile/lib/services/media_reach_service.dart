import '../core/api/api_client.dart';

class MediaReachService {
  MediaReachService(this._api);

  final ApiClient _api;

  Future<MediaReachJob> startCrawl(List<String> mediaNames) async {
    final data = await _api.postJson('/tools/media-reach/crawl', {'media_names': mediaNames});
    return MediaReachJob.fromJson(data);
  }

  Future<MediaReachJob> getJob(String jobId) async {
    final data = await _api.getJson('/tools/media-reach/crawl/$jobId');
    return MediaReachJob.fromJson(data);
  }

  Future<({List<String> names, int skipped})> parseTargets({
    required List<int> bytes,
    required String filename,
  }) async {
    final data = await _api.uploadMultipart(
      '/tools/media-reach/parse-targets',
      fileField: 'file',
      bytes: bytes,
      filename: filename,
    );
    final names = (data['media_names'] as List<dynamic>? ?? []).map((e) => '$e').toList();
    return (names: names, skipped: data['skipped'] as int? ?? 0);
  }
}

class MediaReachJob {
  const MediaReachJob({
    required this.jobId,
    required this.status,
    required this.total,
    required this.completed,
    this.currentMedia,
    this.error,
    this.results = const [],
  });

  final String jobId;
  final String status;
  final int total;
  final int completed;
  final String? currentMedia;
  final String? error;
  final List<Map<String, dynamic>> results;

  bool get isDone => status == 'completed' || status == 'failed';

  factory MediaReachJob.fromJson(Map<String, dynamic> json) => MediaReachJob(
        jobId: json['job_id'] as String,
        status: json['status'] as String? ?? 'pending',
        total: json['total'] as int? ?? 0,
        completed: json['completed'] as int? ?? 0,
        currentMedia: json['current_media'] as String?,
        error: json['error'] as String?,
        results: (json['results'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}
