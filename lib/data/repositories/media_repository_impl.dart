import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:ciel_mobile/data/api/dio_error_mapper.dart';
import 'package:ciel_mobile/data/dto/media_upload_dtos.dart';
import 'package:ciel_mobile/data/dto/models_dtos.dart';
import 'package:ciel_mobile/domain/entities/media.dart';
import 'package:ciel_mobile/domain/repositories/media_repository.dart';
import 'package:dio/dio.dart';

class MediaRepositoryImpl implements MediaRepository {
  MediaRepositoryImpl({
    required Dio apiDio,
    required Dio presignedUploadDio,
  }) : _api = apiDio,
       _upload = presignedUploadDio;

  final Dio _api;
  final Dio _upload;

  @override
  Future<MediaUploadIntent> createUploadIntent({
    required String contentType,
    required int bytes,
  }) async {
    try {
      final res = await _api.post<Map<String, dynamic>>(
        '/media/upload',
        data: mediaUploadIntentRequestJson(
          contentType: contentType,
          bytes: bytes,
        ),
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final dto = MediaUploadIntentResponseDto.fromJson(data);
        final headers = <String, String>{};
        for (final h in dto.headers) {
          headers[h.name] = h.value;
        }
        return MediaUploadIntent(
          uploadId: dto.uploadId,
          uploadUrl: dto.uploadUrl,
          headers: headers,
        );
      }
      throw AppException('Failed to start upload', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> uploadBytes({
    required String uploadUrl,
    required Map<String, String> headers,
    required List<int> data,
  }) async {
    try {
      final res = await _upload.put<void>(
        uploadUrl,
        data: data,
        options: Options(headers: headers),
      );
      if (res.statusCode == null || res.statusCode! >= 400) {
        throw AppException('Upload failed', cause: res.statusMessage);
      }
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> completeUpload(String uploadId) async {
    try {
      await _api.post<void>('/media/upload/$uploadId/complete');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<MediaUploadStatus> uploadStatus(String uploadId) async {
    try {
      final res = await _api.get<Map<String, dynamic>>(
        '/media/upload/$uploadId/status',
      );
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        final dto = MediaUploadStatusDto.fromJson(data);
        return MediaUploadStatus(
          status: dto.status,
          processedMediaId: dto.processedMediaId,
        );
      }
      throw AppException(
        'Failed to get upload status',
        cause: res.statusMessage,
      );
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<Media> fetchMedia(String id) async {
    try {
      final res = await _api.get<Map<String, dynamic>>('/media/$id');
      final data = res.data;
      if (res.statusCode == 200 && data != null) {
        return MediaDto.fromJson(data).toDomain();
      }
      throw AppException('Failed to load media', cause: res.statusMessage);
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }

  @override
  Future<void> deleteMedia(String id) async {
    try {
      await _api.delete<void>('/media/$id');
    } on DioException catch (e) {
      throw mapDioException(e);
    }
  }
}
