import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final Object? code;

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    final message = data is Map<String, dynamic> ? data['message']?.toString() : null;
    return ApiException(
      message ?? error.message ?? '网络请求失败',
      statusCode: error.response?.statusCode,
      code: error.type,
    );
  }

  @override
  String toString() => message;
}
