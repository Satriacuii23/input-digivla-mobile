import '../core/api/api_client.dart';

class DashboardStats {
  const DashboardStats({
    required this.totalTv,
    required this.totalRadio,
    required this.totalOnline,
    required this.todayTv,
    required this.todayRadio,
    required this.todayOnline,
    required this.totalMedia,
  });

  final int totalTv;
  final int totalRadio;
  final int totalOnline;
  final int todayTv;
  final int todayRadio;
  final int todayOnline;
  final int totalMedia;
}

class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<DashboardStats> fetchStats() async {
    final results = await Future.wait([
      _api.getJson('/articles/stats/all'),
      _api.getJson('/articles/stats/today'),
      _api.getJson('/media/stats'),
    ]);

    final all = results[0];
    final today = results[1];
    final media = results[2];

    return DashboardStats(
      totalTv: _int(all['total_tv']),
      totalRadio: _int(all['total_radio']),
      totalOnline: _int(all['total_online']),
      todayTv: _int(today['tv']),
      todayRadio: _int(today['radio']),
      todayOnline: _int(today['online']),
      totalMedia: _int(media['total_media']),
    );
  }

  int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}
