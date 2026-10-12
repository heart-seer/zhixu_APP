import 'dart:developer' as developer;

abstract final class AppLogger {
  static void info(String message, {String name = 'zhixu'}) => developer.log(message, name: name);
  static void error(String message, Object error, StackTrace stackTrace, {String name = 'zhixu'}) => developer.log(message, name: name, error: error, stackTrace: stackTrace, level: 1000);
}
