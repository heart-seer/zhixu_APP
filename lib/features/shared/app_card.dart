import 'package:flutter/material.dart';

class AppCardTimeRow extends StatelessWidget {
  const AppCardTimeRow({
    required this.leading,
    required this.text,
    required this.style,
    required this.spacing,
    this.trailing = const [],
    super.key,
  });

  final Widget leading;
  final String text;
  final TextStyle style;
  final double spacing;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      leading,
      SizedBox(width: spacing),
      Expanded(child: Text(text, style: style)),
      ...trailing,
    ],
  );
}

class AppAccentCard extends StatelessWidget {
  const AppAccentCard({
    required this.child,
    required this.accentColor,
    required this.padding,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE3E7F0),
    this.borderRadius = 14,
    this.clipRadius,
    this.boxShadow = const [],
    this.accentWidth = 4,
    this.intrinsicHeight = false,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    super.key,
  });

  final Widget child;
  final Color accentColor;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double? clipRadius;
  final List<BoxShadow> boxShadow;
  final double accentWidth;
  final bool intrinsicHeight;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        SizedBox(width: accentWidth),
        Expanded(
          child: Padding(padding: padding, child: child),
        ),
      ],
    );
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(clipRadius ?? borderRadius),
      child: Stack(
        children: [
          intrinsicHeight ? IntrinsicHeight(child: content) : content,
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: accentWidth,
            child: ColoredBox(color: accentColor),
          ),
        ],
      ),
    );
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: boxShadow,
      ),
      child: clipped,
    );
  }
}
