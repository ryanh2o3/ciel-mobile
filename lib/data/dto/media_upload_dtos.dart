class MediaUploadHeaderDto {
  MediaUploadHeaderDto({required this.name, required this.value});

  factory MediaUploadHeaderDto.fromJson(Map<String, dynamic> json) {
    return MediaUploadHeaderDto(
      name: json['name'] as String,
      value: json['value'] as String,
    );
  }

  final String name;
  final String value;
}

class MediaUploadIntentResponseDto {
  MediaUploadIntentResponseDto({
    required this.uploadId,
    required this.objectKey,
    required this.uploadUrl,
    required this.expiresInSeconds,
    required this.headers,
  });

  factory MediaUploadIntentResponseDto.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['headers'] as List<dynamic>? ?? [];
    return MediaUploadIntentResponseDto(
      uploadId: json['upload_id'] as String,
      objectKey: json['object_key'] as String,
      uploadUrl: json['upload_url'] as String,
      expiresInSeconds: (json['expires_in_seconds'] as num).toInt(),
      headers: rawHeaders
          .map((e) => MediaUploadHeaderDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String uploadId;
  final String objectKey;
  final String uploadUrl;
  final int expiresInSeconds;
  final List<MediaUploadHeaderDto> headers;
}

class MediaUploadStatusDto {
  MediaUploadStatusDto({required this.status, this.processedMediaId});

  factory MediaUploadStatusDto.fromJson(Map<String, dynamic> json) {
    return MediaUploadStatusDto(
      status: json['status'] as String,
      processedMediaId: json['processed_media_id'] as String?,
    );
  }

  final String status;
  final String? processedMediaId;
}

Map<String, dynamic> mediaUploadIntentRequestJson({
  required String contentType,
  required int bytes,
}) {
  return {'content_type': contentType, 'bytes': bytes};
}
