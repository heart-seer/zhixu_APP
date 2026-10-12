import 'package:flutter/material.dart';

import '../../app/theme/app_dimensions.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({super.key, required this.controller, required this.label, this.hint, this.keyboardType, this.obscureText = false, this.prefix, this.suffix, this.validator, this.maxLength});

  final TextEditingController controller;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefix;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final int? maxLength;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: AppDimensions.inputHeight,
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          maxLength: maxLength,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: prefix, suffixIcon: suffix, counterText: ''),
        ),
      );
}
