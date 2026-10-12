import 'environment.dart';

abstract final class AppConfig {
  static const environment = Environment.development;
  static const apiBaseUrl = 'https://api.example.com';
  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 15);
}
