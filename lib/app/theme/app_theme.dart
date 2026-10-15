import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static final _dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
    side: const BorderSide(color: AppColors.border),
  );

  static final _pickerActionStyle = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: const Size(48, 48),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
    ),
    textTheme: const TextTheme(
      headlineMedium: AppTextStyles.heading,
      titleLarge: AppTextStyles.title,
      bodyLarge: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x140B2050),
      shape: _dialogShape,
      titleTextStyle: AppTextStyles.title,
      contentTextStyle: AppTextStyles.body,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: _dialogShape,
      headerBackgroundColor: AppColors.surface,
      headerForegroundColor: AppColors.textPrimary,
      headerHeadlineStyle: AppTextStyles.heading,
      headerHelpStyle: AppTextStyles.caption,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return AppColors.textSecondary;
        }
        if (states.contains(WidgetState.selected)) return Colors.white;
        return AppColors.textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? AppColors.primary : null;
      }),
      todayForegroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.primary;
      }),
      todayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.transparent;
      }),
      todayBorder: const BorderSide(color: AppColors.primary),
      yearForegroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textPrimary;
      }),
      yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
        return states.contains(WidgetState.selected) ? AppColors.primary : null;
      }),
      cancelButtonStyle: _pickerActionStyle,
      confirmButtonStyle: _pickerActionStyle,
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: AppColors.surface,
      shape: _dialogShape,
      helpTextStyle: AppTextStyles.caption,
      hourMinuteColor: WidgetStateColor.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: .1)
            : AppColors.background;
      }),
      hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textPrimary;
      }),
      dayPeriodColor: WidgetStateColor.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary.withValues(alpha: .1)
            : AppColors.surface;
      }),
      dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textSecondary;
      }),
      dayPeriodBorderSide: const BorderSide(color: AppColors.border),
      dialBackgroundColor: AppColors.background,
      dialHandColor: AppColors.primary,
      dialTextColor: WidgetStateColor.resolveWith((states) {
        return states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textPrimary;
      }),
      cancelButtonStyle: _pickerActionStyle,
      confirmButtonStyle: _pickerActionStyle,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingMd,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
  );
}
