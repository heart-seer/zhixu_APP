import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/shared/data_providers.dart';
import '../features/shared/local_repository.dart';
import '../features/shared/remote_repository.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  int _shownErrorVersion = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<AppRepository>(repositoryProvider, (_, repository) {
      if (repository is! RemoteRepository) return;
      if (repository.errorVersion <= _shownErrorVersion) return;
      _shownErrorVersion = repository.errorVersion;
      final messenger = _messengerKey.currentState;
      if (messenger == null) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(repository.lastError ?? '网络异常，请稍后重试'),
            action: SnackBarAction(
              label: '重试',
              onPressed: repository.refresh,
            ),
          ),
        );
    });

    return MaterialApp.router(
      title: '智序',
      theme: AppTheme.light,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
