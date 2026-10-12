import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../core/storage/secure_storage.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await ref.read(secureStorageProvider).readToken();
      if (context.mounted) context.go(token == null ? RouteNames.auth : RouteNames.home);
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
