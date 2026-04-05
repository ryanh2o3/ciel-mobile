import 'package:ciel_mobile/core/errors/app_exception.dart';
import 'package:dio/dio.dart';

AppException mapDioException(DioException e) {
  final status = e.response?.statusCode;
  final body = e.response?.data;
  var message = 'Request failed';
  if (body is Map && body['message'] is String) {
    message = body['message'] as String;
  } else if (status == 401) {
    message = 'Unauthorized';
  } else if (status != null) {
    message = 'Error $status';
  } else if (e.message != null) {
    message = e.message!;
  }
  return AppException(message, cause: e);
}
