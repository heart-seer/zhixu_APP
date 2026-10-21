import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

/// 附加访问令牌；访问令牌过期时用刷新令牌换新令牌并重试一次。
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storage, String baseUrl, {Dio? refreshClient})
      : _refreshClient = refreshClient ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ));

  final SecureStorage _storage;
  final Dio _refreshClient;
  Future<String?>? _pendingRefresh;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        !options.path.startsWith('/auth/') &&
        options.extra['retried'] != true;
    if (!shouldRefresh) {
      handler.next(err);
      return;
    }
    final accessToken = await _refreshAccessToken();
    if (accessToken == null) {
      await _storage.clear();
      handler.next(err);
      return;
    }
    options.headers['Authorization'] = 'Bearer $accessToken';
    options.extra['retried'] = true;
    try {
      handler.resolve(await _refreshClient.fetch(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<String?> _refreshAccessToken() {
    final pending = _pendingRefresh;
    if (pending != null) return pending;
    final future = _performRefresh();
    _pendingRefresh = future.whenComplete(() => _pendingRefresh = null);
    return _pendingRefresh!;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final response = await _refreshClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final body = response.data;
      final data = body is Map<String, dynamic> ? body['data'] : null;
      if (data is! Map<String, dynamic>) return null;
      final accessToken = data['accessToken']?.toString();
      if (accessToken == null || accessToken.isEmpty) return null;
      await _storage.saveToken(accessToken);
      final nextRefresh = data['refreshToken']?.toString();
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        await _storage.saveRefreshToken(nextRefresh);
      }
      return accessToken;
    } catch (_) {
      return null;
    }
  }
}
