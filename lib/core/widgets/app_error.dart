import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppError extends StatelessWidget {
  const AppError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('重试')),
        ]),
      );
}
