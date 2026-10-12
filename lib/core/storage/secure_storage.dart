import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'storage_keys.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: StorageKeys.accessToken);
  Future<void> saveToken(String token) => _storage.write(key: StorageKeys.accessToken, value: token);
  Future<void> deleteToken() => _storage.delete(key: StorageKeys.accessToken);
  Future<void> saveRefreshToken(String token) => _storage.write(key: StorageKeys.refreshToken, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: StorageKeys.refreshToken);
  Future<void> clear() => _storage.deleteAll();
}
