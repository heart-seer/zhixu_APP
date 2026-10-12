import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppEmpty extends StatelessWidget {
  const AppEmpty({super.key, this.message = '暂无内容', this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        ]),
      );
}
