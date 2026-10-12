import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage.dart';
import '../config/app_config.dart';
import '../config/environment.dart';
import 'route_names.dart';

final routeGuardProvider = Provider<RouteGuard>((ref) => RouteGuard(ref));

class RouteGuard {
  RouteGuard(this._ref);

  final Ref _ref;

  Future<String?> redirect(String location) async {
    if (location == RouteNames.auth ||
        location == RouteNames.register ||
        location == RouteNames.splash) {
      return null;
    }
    // 开发环境允许直接打开首页，便于预览 UI；其他环境仍必须完成登录认证。
    if ([RouteNames.home, RouteNames.tasks, RouteNames.calendar, RouteNames.messages, RouteNames.profile].contains(location) && AppConfig.environment == Environment.development) return null;
    final token = await _ref.read(secureStorageProvider).readToken();
    return token == null ? RouteNames.auth : null;
  }
}
