import '../core/api/api_client.dart';
import '../models/media.dart';

class MediaService {
  MediaService(this._api);

  final ApiClient _api;

  Future<PaginatedMedia> listMedia({
    int page = 1,
    int limit = 20,
    int? mediaTypeId,
    String? search,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (mediaTypeId != null) query['media_type_id'] = '$mediaTypeId';
    if (search != null && search.isNotEmpty) query['search'] = search;

    final data = await _api.getJson('/media/', query: query);
    final items = (data['data'] as List<dynamic>? ?? [])
        .map((e) => MediaModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final pagination = data['pagination'] as Map<String, dynamic>?;
    return PaginatedMedia(
      items: items,
      page: pagination?['page'] as int? ?? page,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      total: pagination?['total'] as int? ?? items.length,
    );
  }

  Future<List<MediaModel>> listByType(int mediaTypeId) async {
    final list = await _api.getJsonList('/media/type/by-id/$mediaTypeId');
    return list.map((e) => MediaModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<MediaTypeModel>> listTypes() async {
    final list = await _api.getJsonList('/media/types/all');
    return list.map((e) => MediaTypeModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<MediaModel> createMedia({
    required String mediaName,
    required int mediaType,
    String language = 'IDN',
    String status = 'Active',
    String? tier,
    int? circulation,
    double? rateBw,
    double? rateFc,
  }) async {
    final body = <String, dynamic>{
      'media_name': mediaName.trim(),
      'media_type': mediaType,
      'language': language,
      'status': status,
    };
    if (tier != null && tier.isNotEmpty) body['tier'] = tier;
    if (circulation != null) body['circulation'] = circulation;
    if (rateBw != null) body['rate_bw'] = rateBw;
    if (rateFc != null) body['rate_fc'] = rateFc;

    final data = await _api.postJson('/media/', body);
    return MediaModel.fromJson(data);
  }

  Future<Map<String, dynamic>?> checkDuplicate(String mediaName) async {
    if (mediaName.trim().length < 2) return null;
    final data = await _api.getJson('/media/check-duplicate', query: {'media_name': mediaName.trim()});
    if (data['exists'] == true && data['is_exact_match'] == true) {
      return data['media'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<MediaModel> getMedia(int mediaId) async {
    final data = await _api.getJson('/media/$mediaId');
    return MediaModel.fromJson(data);
  }

  Future<MediaModel> updateMedia(int mediaId, Map<String, dynamic> body) async {
    final data = await _api.putJson('/media/$mediaId', body);
    return MediaModel.fromJson(data);
  }

  Future<void> deleteMedia(int mediaId) async {
    await _api.deleteJson('/media/$mediaId');
  }
}

class PaginatedMedia {
  final List<MediaModel> items;
  final int page;
  final int totalPages;
  final int total;

  const PaginatedMedia({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  bool get hasMore => page < totalPages;
}
