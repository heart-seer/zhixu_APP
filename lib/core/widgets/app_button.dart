import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';
import '../../app/theme/app_text_styles.dart';

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.enabled = true, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final Widget? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppDimensions.buttonHeight,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: enabled && !isLoading ? onPressed : null,
          icon: isLoading ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)) : icon ?? const SizedBox.shrink(),
          label: Text(label, style: AppTextStyles.button),
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMd))),
        ),
      );
}
