import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/app_config.dart';
import '../storage/secure_storage.dart';
import 'auth_interceptor.dart';
import 'error_interceptor.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient(ref.read(secureStorageProvider)));

class DioClient {
  DioClient(SecureStorage storage)
      : dio = Dio(BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: AppConfig.connectTimeout,
          receiveTimeout: AppConfig.receiveTimeout,
          headers: {'Accept': 'application/json'},
        )) {
    dio.interceptors.addAll([
      AuthInterceptor(storage, AppConfig.apiBaseUrl),
      ErrorInterceptor(),
    ]);
  }

  final Dio dio;
}
