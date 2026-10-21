import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/secure_storage.dart';
import 'local_repository.dart';
import 'remote_repository.dart';

final repositoryProvider = ChangeNotifierProvider<AppRepository>((ref) {
  final repository = RemoteRepository(
    dio: ref.read(dioClientProvider).dio,
    storage: ref.read(secureStorageProvider),
  );
  unawaited(repository.bootstrap());
  return repository;
});
