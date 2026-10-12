import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({super.key, this.imageUrl, this.radius = 24, this.fallbackIcon = Icons.person_outline});

  final String? imageUrl;
  final double radius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.border,
        foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
        onForegroundImageError: imageUrl == null ? null : (_, _) {},
        child: Icon(fallbackIcon, color: AppColors.textSecondary),
      );
}
