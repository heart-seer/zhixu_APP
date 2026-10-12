import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';

class MainBottomNav extends StatelessWidget {
  const MainBottomNav({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const _labels = ['首页', '任务', '日历', '消息', '我的'];
  static const _icons = [Icons.home_rounded, Icons.check_box_outlined, Icons.calendar_month_outlined, Icons.chat_bubble_outline_rounded, Icons.person_outline_rounded];
  static const _routes = [RouteNames.home, RouteNames.tasks, RouteNames.calendar, RouteNames.messages, RouteNames.profile];

  @override
  Widget build(BuildContext context) => Container(height: 62, decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: List.generate(_labels.length, (index) {
    final selected = index == selectedIndex;
    return InkWell(onTap: () { if (!selected) context.go(_routes[index]); }, child: SizedBox(width: 56, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(_icons[index], size: 21, color: selected ? AppColors.primary : AppColors.textSecondary), Text(_labels[index], style: TextStyle(fontSize: 10, color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w700 : FontWeight.normal))])));
  })));
}
