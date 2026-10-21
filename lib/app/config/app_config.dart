import 'package:flutter/foundation.dart';

import 'environment.dart';

abstract final class AppConfig {
  static const environment = Environment.development;

  /// 本地后端地址：Android 模拟器需通过 10.0.2.2 访问宿主机。
  static String get apiBaseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://127.0.0.1:8080';
  }

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
