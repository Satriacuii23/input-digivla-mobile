class MediaModel {
  final int mediaId;
  final String mediaName;
  final int mediaType;
  final String? typeName;
  final String? typeDisplay;
  final int? circulation;
  final double? rateBw;
  final double? rateFc;
  final String? tier;
  final String? language;
  final String? status;

  const MediaModel({
    required this.mediaId,
    required this.mediaName,
    required this.mediaType,
    this.typeName,
    this.typeDisplay,
    this.circulation,
    this.rateBw,
    this.rateFc,
    this.tier,
    this.language,
    this.status,
  });

  factory MediaModel.fromJson(Map<String, dynamic> json) {
    return MediaModel(
      mediaId: json['media_id'] as int,
      mediaName: json['media_name'] as String? ?? '',
      mediaType: json['media_type'] as int? ?? 0,
      typeName: json['type_name'] as String?,
      typeDisplay: json['type_display'] as String?,
      circulation: json['circulation'] as int?,
      rateBw: _toDouble(json['rate_bw']),
      rateFc: _toDouble(json['rate_fc']),
      tier: json['tier'] as String?,
      language: json['language'] as String?,
      status: json['status'] as String?,
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class MediaTypeModel {
  final int mediaTypeId;
  final String? mediaTypeName;
  final String? mediaTypeEn;

  const MediaTypeModel({
    required this.mediaTypeId,
    this.mediaTypeName,
    this.mediaTypeEn,
  });

  factory MediaTypeModel.fromJson(Map<String, dynamic> json) {
    return MediaTypeModel(
      mediaTypeId: json['media_type_id'] as int,
      mediaTypeName: json['media_type_name'] as String?,
      mediaTypeEn: json['media_type_en'] as String?,
    );
  }

  String get label => mediaTypeEn ?? mediaTypeName ?? 'Type $mediaTypeId';
}
