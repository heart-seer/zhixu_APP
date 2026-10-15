import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showDialog<T>(
    context: context,
    useSafeArea: true,
    builder: (context) => AppDialog(
      title: title,
      child: Builder(builder: builder),
    ),
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: const BorderSide(color: Color(0xFFDCE7FA)),
    ),
    shadowColor: const Color(0x260B50C8),
    elevation: 12,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: '关闭',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF0F4FB),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: child,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<T?> pushAppPage<T>({
  required BuildContext context,
  required String title,
  required WidgetBuilder builder,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return Navigator.of(context).push<T>(
    MaterialPageRoute<T>(
      builder: (context) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(20),
            child: Builder(builder: builder),
          ),
        ),
      ),
    ),
  );
}
