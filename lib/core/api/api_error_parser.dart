import 'package:dio/dio.dart';
import '../errors/app_exception.dart';

abstract final class ApiErrorParser {
  static AppException parse(Object error) {
    if (error is! DioException) {
      return const AppException('Something went wrong. Please try again.');
    }
    final data = error.response?.data;
    if (data is Map) {
      final fields = <String, List<String>>{};
      if (data['errors'] is Map) {
        for (final entry in (data['errors'] as Map).entries) {
          fields[entry.key.toString()] =
              entry.value is List
                  ? (entry.value as List)
                      .map((item) => item.toString())
                      .toList()
                  : [entry.value.toString()];
        }
      }
      return AppException(
        data['message']?.toString() ?? 'The request could not be completed.',
        code: data['code']?.toString(),
        fieldErrors: fields,
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return const AppException('No connection to the server.');
    }
    if ({
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout,
    }.contains(error.type)) {
      return const AppException('The request timed out. Please try again.');
    }
    return const AppException('The request could not be completed.');
  }
}
