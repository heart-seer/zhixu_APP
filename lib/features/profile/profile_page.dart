import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../shared/main_bottom_nav.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _reminders = true;
  bool _autoSchedule = true;
  String _focusWindow = '09:00 - 22:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(backgroundColor: const Color(0xFFF8F9FF), title: const Row(children: [Text('智序', style: TextStyle(fontWeight: FontWeight.w700)), SizedBox(width: 8), _ProTag()]), actions: [IconButton(onPressed: () => _message('已同步最新云端配置'), icon: const Icon(Icons.sync)), IconButton(onPressed: () => _message('AI 助理已就绪'), icon: const Icon(Icons.auto_awesome, color: AppColors.primary))]),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: [
        _card(child: Column(children: [
          Row(children: [CircleAvatar(radius: 29, backgroundColor: const Color(0xFFDBE1FF), child: const Icon(Icons.person, size: 34, color: AppColors.primary)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('林知序', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), SizedBox(height: 4), Text('高级产品设计专家 · 考研备考中', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))])), IconButton(onPressed: () => _message('个人档案编辑入口已打开'), icon: const Icon(Icons.qr_code_2_outlined, color: AppColors.textSecondary))]),
          const SizedBox(height: 15),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11), decoration: const BoxDecoration(color: Color(0xFFEFF4FF), borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))), child: Row(children: [const Icon(Icons.stars_rounded, color: Color(0xFF712AE2)), const SizedBox(width: 8), const Expanded(child: Text('智序 AI Pro · 智能协同版', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))), TextButton(onPressed: () => _message('AI Pro 权益管理'), child: const Text('特权管理'))])),
        ])),
        const SizedBox(height: 12),
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.insights_outlined, color: AppColors.primary), SizedBox(width: 8), Text('效能周报看板', style: TextStyle(fontWeight: FontWeight.w700)), Spacer(), Text('第43周', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))]), const SizedBox(height: 14), Row(children: [_metric('38', '本周交付', '+12.5%'), _metric('42.5h', '专注时长', '+8.2%'), _metric('92%', '计划达成', '优秀')]), Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: () => _message('完整周报已打开'), icon: const Icon(Icons.arrow_forward, size: 16), label: const Text('完整周报')))])),
        const SizedBox(height: 12),
        _section('偏好设置', [
          _setting(Icons.notifications_none, '智能提醒', '接收任务截止与日程通知', trailing: Switch(value: _reminders, onChanged: (value) => setState(() => _reminders = value))),
          _setting(Icons.auto_awesome, 'AI 自动排程', '为待办任务推荐专注时段', trailing: Switch(value: _autoSchedule, onChanged: (value) => setState(() => _autoSchedule = value))),
          _setting(Icons.schedule, '专注时间', _focusWindow, onTap: _pickFocusWindow),
        ]),
        const SizedBox(height: 12),
        _section('平台与账号', [
          _setting(Icons.link, '已连接平台', '5 个平台已联通', onTap: () => _message('平台连接管理已打开')),
          _setting(Icons.lock_outline, '账号与安全', '密码、手机号码与隐私', onTap: () => _message('账号安全设置已打开')),
          _setting(Icons.cloud_outlined, '数据同步', '最近同步：刚刚', onTap: () => _message('数据同步完成')),
        ]),
        const SizedBox(height: 12),
        _section('更多', [
          _setting(Icons.help_outline, '帮助与反馈', '常见问题与意见反馈', onTap: () => _message('帮助与反馈页面已打开')),
          _setting(Icons.info_outline, '关于智序', '版本 1.0.0', onTap: () => _message('智序 AI 工作台')),
        ]),
        const SizedBox(height: 14),
        OutlinedButton(onPressed: _confirmLogout, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFBA1A1A), side: const BorderSide(color: Color(0xFFEDC4C1)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('退出登录')),
      ]),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 4),
    );
  }

  Widget _card({required Widget child}) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border.withValues(alpha: .5))), child: child);
  Widget _metric(String value, String label, String delta) => Expanded(child: Container(margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5), decoration: BoxDecoration(color: const Color(0xFFF3F6FC), borderRadius: BorderRadius.circular(12)), child: Column(children: [Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)), const SizedBox(height: 6), Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)), const SizedBox(height: 4), Text(delta, style: const TextStyle(fontSize: 10, color: Color(0xFF059669)))])));
  Widget _section(String title, List<Widget> children) => _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))), ...children]));
  Widget _setting(IconData icon, String title, String subtitle, {Widget? trailing, VoidCallback? onTap}) => ListTile(dense: true, leading: Icon(icon, color: AppColors.primary, size: 21), title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)), subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)), trailing: trailing ?? const Icon(Icons.chevron_right, size: 19, color: AppColors.textSecondary), onTap: onTap);

  Future<void> _pickFocusWindow() async {
    final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0), helpText: '选择专注开始时间');
    if (time == null || !mounted) return;
    setState(() => _focusWindow = '${time.format(context)} - 22:00');
  }

  void _confirmLogout() => showDialog<void>(context: context, builder: (context) => AlertDialog(title: const Text('退出登录'), content: const Text('确定要退出当前账号吗？'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')), FilledButton(onPressed: () { Navigator.pop(context); _message('请重新登录以继续使用'); }, child: const Text('退出'))]));
  void _message(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _ProTag extends StatelessWidget {
  const _ProTag();
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEADDFF), borderRadius: BorderRadius.circular(20)), child: const Text('Pro', style: TextStyle(fontSize: 10, color: Color(0xFF712AE2), fontWeight: FontWeight.w700)));
}
