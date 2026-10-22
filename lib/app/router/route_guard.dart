import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/secure_storage.dart';
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
    final token = await _ref.read(secureStorageProvider).readToken();
    return token == null || token.isEmpty ? RouteNames.auth : null;
  }
}
