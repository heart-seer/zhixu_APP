import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/app_presentation.dart';
import '../../core/storage/secure_storage.dart';
import '../shared/main_bottom_nav.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  static const _blue = Color(0xFF0052D9);
  static const _purple = Color(0xFF7928FF);
  static const _green = Color(0xFF00B887);
  bool _reminders = true;
  int _focusMinutes = 90;
  int _appearance = 0;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 22, minute: 30);

  String _timeText(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  String get _focusWindow => '${_timeText(_start)} - ${_timeText(_end)}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F9FF),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF8F9FF),
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          InkWell(
            onTap: _showProfile,
            borderRadius: BorderRadius.circular(18),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFE5EDFF),
              child: Icon(Icons.person, size: 23, color: _blue),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            '智序',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 6),
          const _ProTag(),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'AI 助理说明',
          onPressed: _showAi,
          icon: const Icon(Icons.auto_awesome, color: _purple, size: 23),
        ),
        IconButton(
          tooltip: '同步说明',
          onPressed: _showSync,
          icon: const Icon(
            Icons.sync,
            color: AppColors.textSecondary,
            size: 23,
          ),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
      children: [
        _profileCard(),
        const SizedBox(height: 14),
        _weeklyCard(),
        const SizedBox(height: 14),
        _section('AI 助理与算法配置', Icons.psychology_outlined, _purple, [
          _setting(
            Icons.tune,
            _blue,
            'AI 自动编排偏好',
            subtitle: '当前偏好：深度专注优先(${_focusMinutes}m 块)',
            trailing: _pill('调校', _blue),
            onTap: _showPreferences,
          ),
          _setting(
            Icons.bedtime_outlined,
            _purple,
            '作息与勿扰时段',
            subtitle: '$_focusWindow · 弹性免打扰保护',
            trailing: const Text(
              '已生效',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            onTap: _pickFocusWindow,
          ),
          _setting(
            Icons.notifications_active_outlined,
            const Color(0xFFFFC964),
            '智能提醒梯度',
            subtitle: '前15分钟自适应声光+手环震',
            trailing: SizedBox(
              width: 42,
              child: Transform.scale(
                scale: .78,
                child: Switch(
                  value: _reminders,
                  activeTrackColor: _blue,
                  thumbColor: const WidgetStatePropertyAll(Colors.white),
                  trackOutlineColor: const WidgetStatePropertyAll(
                    Colors.transparent,
                  ),
                  onChanged: (value) => setState(() => _reminders = value),
                ),
              ),
            ),
            chevron: false,
            onTap: () => _showPanel('智能提醒梯度', [
              _detail('本页偏好', _reminders ? '开启' : '关闭'),
              const Text('开关仅修改本页状态。系统通知、声光设备与手环服务未接入，不会实际发送提醒。'),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        _platformCard(),
        const SizedBox(height: 14),
        _section('系统与偏好', Icons.settings_outlined, AppColors.textSecondary, [
          _setting(
            Icons.palette_outlined,
            const Color(0xFF52657A),
            '界面外观',
            trailing: _appearanceControl(),
            chevron: false,
            onTap: () => _showPanel('界面外观', [
              _detail('本页选项预览', ['浅色', '深色', '跟随'][_appearance]),
              const Text('三段按钮仅预览本页选中状态，未修改全局主题，离开页面后可能重置。'),
            ]),
          ),
          _setting(
            Icons.storage_rounded,
            const Color(0xFF52657A),
            '存储与离线缓存',
            subtitle: '离线日历与知识库 · 142.8 MB',
            trailing: const Text(
              '清理',
              style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
            onTap: _confirmCache,
          ),
          _setting(
            Icons.shield_outlined,
            _green,
            '隐私安全与数据加密',
            subtitle: '端侧密文计算 · 知识沙箱隔离已开启',
            trailing: _pill('高安全', _green),
            onTap: _showAccount,
          ),
        ]),
        const SizedBox(height: 14),
        _card(
          child: Column(
            children: [
              _setting(
                Icons.help_outline,
                const Color(0xFF52657A),
                '帮助反馈与 AI 使用指南',
                onTap: _showHelp,
              ),
              _divider(),
              _setting(
                Icons.info_outline,
                const Color(0xFF52657A),
                '关于智序 (SmartOrder)',
                trailing: const Text(
                  'v2.4.0 最新',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                onTap: _showAbout,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout, size: 17),
          label: const Text(
            '退出登录 / 切换智序账号',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE22323),
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '智序 AI · 智能极简知识工坊',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    ),
    bottomNavigationBar: const MainBottomNav(selectedIndex: 4),
  );

  Widget _profileCard() => _card(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Colors.white, Color(0xFFF0F5FF)]),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _blue, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFFE5EDFF),
                      child: Icon(Icons.person, size: 36, color: _blue),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '林知序',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Alex Lin',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text('高级产品设计专家 · 考研备考中', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ),
              IconButton(
                tooltip: '示例个人档案',
                onPressed: _showProfile,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 44),
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.qr_code_2,
                  size: 19,
                  color: Color(0xFF52657A),
                ),
              ),
            ],
          ),
        ),
        Container(
          color: const Color(0xFFF2F5FF),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '智序 AI Pro · 智能协同版',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: _showPro,
                style: TextButton.styleFrom(
                  foregroundColor: _blue,
                  padding: const EdgeInsets.only(left: 6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '特权管理',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 15),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _weeklyCard() => _card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 14,
                decoration: BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '效能周报看板',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              const Text(
                '第43周',
                style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
              const Spacer(),
              InkWell(
                onTap: _showWeeklyReport,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        '完整周报',
                        style: TextStyle(
                          fontSize: 10,
                          color: _blue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: _blue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _metric('38', '项', '本周交付任务', '+12.5%', _blue, _green),
              const SizedBox(width: 8),
              _metric('42.5', 'h', '专注时长', '超越达标', _purple, _purple),
              const SizedBox(width: 8),
              _metric(
                '94',
                '%',
                'AI 协同采纳',
                '高音效',
                const Color(0xFF172B45),
                _blue,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _metric(
    String value,
    String unit,
    String label,
    String delta,
    Color color,
    Color deltaColor,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: TextStyle(
              fontSize: 10,
              color: deltaColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _platformCard() => _section(
    '协同平台与数据源连接',
    Icons.hub_outlined,
    _blue,
    [
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(
          children: [
            Row(
              children: [
                _platform('钉钉', Icons.groups_outlined),
                const SizedBox(width: 8),
                _platform('企业微信', Icons.business_center_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _platform('飞书', Icons.near_me_outlined),
                const SizedBox(width: 8),
                _platform('学习通', Icons.school_outlined, pending: true),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '最近一次全量云端对齐：10分钟前',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _showSync,
                  style: TextButton.styleFrom(
                    foregroundColor: _blue,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 40),
                  ),
                  child: const Text(
                    '立即对齐',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
    trailing: const Text(
      '4平台在线',
      style: TextStyle(fontSize: 10, color: _blue, fontWeight: FontWeight.w700),
    ),
  );

  Widget _platform(String name, IconData icon, {bool pending = false}) =>
      Expanded(
        child: Material(
          color: pending ? const Color(0xFFFFFAE9) : const Color(0xFFF8FAFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEDF0F7)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _showPlatforms(name),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  _iconBox(
                    icon,
                    pending ? const Color(0xFFDD9A21) : const Color(0xFF3779FF),
                    background: pending ? const Color(0xFFFFF0C9) : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          pending ? '待同步' : '已连接',
                          style: TextStyle(
                            fontSize: 10,
                            color: pending ? const Color(0xFFBA861D) : _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: pending ? 10 : 7,
                    height: pending ? 10 : 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: pending ? const Color(0xFFFFD78C) : _green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _card({required Widget child}) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border.withValues(alpha: .7)),
    ),
    child: child,
  );

  Widget _section(
    String title,
    IconData icon,
    Color color,
    List<Widget> children, {
    Widget? trailing,
  }) => _card(
    child: Column(
      children: [
        Container(
          color: const Color(0xFFF8FAFF),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        for (var index = 0; index < children.length; index++) ...[
          if (index > 0) _divider(),
          children[index],
        ],
      ],
    ),
  );

  Widget _divider() =>
      const Divider(height: 1, thickness: 1, color: Color(0xFFF4F5F9));

  Widget _iconBox(IconData icon, Color color, {Color? background}) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color:
          background ??
          (color == _purple
              ? const Color(0xFFF0E7FF)
              : const Color(0xFFE7EFFF)),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Icon(icon, size: 18, color: color),
  );

  Widget _pill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color == _green
          ? const Color(0xFFE7FAF3)
          : const Color(0xFFEDF3FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
    ),
  );

  Widget _setting(
    IconData icon,
    Color color,
    String title, {
    String? subtitle,
    Widget? trailing,
    bool chevron = true,
    VoidCallback? onTap,
  }) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _iconBox(icon, color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
          if (chevron)
            const Padding(
              padding: EdgeInsets.only(left: 3),
              child: Icon(
                Icons.chevron_right,
                size: 17,
                color: Color(0xFF52657A),
              ),
            ),
        ],
      ),
    ),
  );

  Widget _appearanceControl() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF2FF),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < 3; index++)
          InkWell(
            onTap: () => setState(() => _appearance = index),
            borderRadius: BorderRadius.circular(5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: _appearance == index ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                ['浅色', '深色', '跟随'][index],
                style: TextStyle(
                  fontSize: 10,
                  color: _appearance == index ? _blue : const Color(0xFF172B45),
                  fontWeight: _appearance == index
                      ? FontWeight.w700
                      : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Future<void> _showPreferences() async {
    var draft = _focusMinutes;
    final result = await showAppDialog<int>(
      context: context,
      title: 'AI 自动编排偏好',
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updatePanel) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('选择深度专注块时长。仅更新本页偏好，未接入 AI 排程服务，不会自动编排任务。'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final minutes in [90, 60, 30])
                  ChoiceChip(
                    label: Text('$minutes 分钟'),
                    selected: draft == minutes,
                    onSelected: (_) => updatePanel(() => draft = minutes),
                  ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('取消'),
                  ),
                ),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, draft),
                    child: const Text('应用'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _focusMinutes = result);
  }

  Future<void> _pickFocusWindow() async {
    final start = await showTimePicker(
      context: context,
      initialTime: _start,
      helpText: '选择作息开始时间（仅本页偏好）',
    );
    if (start == null || !mounted) return;
    final end = await showTimePicker(
      context: context,
      initialTime: _end,
      helpText: '选择作息结束时间（仅本页偏好）',
    );
    if (end == null || !mounted) return;
    setState(() {
      _start = start;
      _end = end;
    });
  }

  void _confirmCache() => _showPanel('存储与离线缓存', [
    _detail('设计示例', '离线日历与知识库 · 142.8 MB'),
    const Text('142.8 MB 为设计示例，暂无实际缓存统计或清理服务。本次未执行删除，未释放空间，也未修改安全存储。'),
  ]);

  void _showPanel(String title, List<Widget> children, {bool page = false}) {
    Widget content(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    if (page) {
      pushAppPage<void>(context: context, title: title, builder: content);
    } else {
      showAppDialog<void>(context: context, title: title, builder: content);
    }
  }

  Widget _detail(String title, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(value),
  );

  void _showProfile() => _showPanel('个人档案 · 示例', [
    _detail('姓名', '林知序 Alex Lin'),
    _detail('职业', '高级产品设计专家'),
    _detail('当前目标', '考研备考中'),
    const Text('以上为示例档案，未接入账号档案或个人二维码服务。头像与勾选徽章仅为设计展示，不代表身份认证。'),
  ], page: true);

  void _showPro() => _showPanel('Pro 权益信息 · 示例', [
    _detail('当前展示方案', '智序 AI Pro · 智能协同版'),
    const Text('会员标识为设计示例，未接入订阅或权益验证服务，无可核实的有效期、额度或订单信息。此处不能购买、续费或管理真实订阅。'),
  ], page: true);

  void _showWeeklyReport() => _showPanel('效能周报 · 第43周 · 示例', [
    _detail('本周交付任务', '38 项 · +12.5%'),
    _detail('专注时长', '42.5 h · 超越达标'),
    _detail('AI 协同采纳', '94% · 高音效'),
    const Text('以上与看板一致，为参考设计中的本地示例指标，未接入真实统计或历史周报服务。'),
  ], page: true);

  void _showPlatforms(String platform) => _showPanel('$platform · 示例连接状态', [
    _detail('设计示例', platform == '学习通' ? '待同步' : '已连接'),
    const Text(
      '页面的“4平台在线”、绿点已连接及学习通待同步均为本地设计示例，不是实际授权结果。钉钉、企业微信、飞书、学习通尚未接入授权或状态查询服务。',
    ),
    const Text('此处不会连接、解绑、重新授权或同步数据。'),
  ]);

  Future<void> _showAccount() async {
    String status;
    try {
      final token = await ref.read(secureStorageProvider).readToken();
      status = token == null || token.isEmpty
          ? '未保存本地登录凭据（开发环境允许直接预览）'
          : '已保存本地登录凭据；未验证云端会话有效性';
    } catch (_) {
      status = '无法读取本地登录状态';
    }
    if (!mounted) return;
    _showPanel('隐私安全与数据加密', [
      _detail('本地登录状态', status),
      _detail('实际安全存储范围', '项目使用 flutter_secure_storage 存储访问令牌和刷新令牌；此处不展示令牌内容。'),
      const Text(
        '“高安全”“端侧密文计算”“知识沙箱隔离已开启”为参考设计示例，不代表项目已实现这些能力。安全存储不等于日历、知识库或所有业务数据均已加密。账号资料及隐私管理服务尚未接入。',
      ),
    ], page: true);
  }

  void _showSync() => _showPanel('数据同步说明 · 未接入', [
    _detail('页面设计示例', '4平台在线 · 最近一次全量云端对齐：10分钟前'),
    _detail('实际同步状态', '未接入云端同步服务，暂无真实同步记录'),
    const Text('本次仅打开说明，不上传、下载、授权或同步数据。页面偏好仅保存在当前页面状态，未持久化，离开后可能重置。'),
  ]);

  void _showAi() => _showPanel('AI 助理 · 未接入', [
    _detail('本页编排偏好', '深度专注优先 · $_focusMinutes 分钟块'),
    _detail('本页作息偏好', _focusWindow),
    _detail('本页智能提醒偏好', _reminders ? '开启' : '关闭'),
    const Text('当前未接入 AI 模型、自动排程或系统通知服务。偏好仅用于本页展示，不调用模型或执行任务。'),
  ]);

  void _showHelp() => _showPanel('帮助反馈与 AI 使用指南', [
    _detail('查看示例信息', '点击完整周报、特权管理、二维码或平台卡片查看说明。底部导航切换其他页面。'),
    _detail('本地偏好', '调校可选择90/60/30分钟；作息可选择起止时间；提醒开关及外观选中状态仅作用于本页。'),
    _detail('退出与切换', '确认后清除本地安全存储中的登录凭据并返回登录页，不执行云端会话注销。'),
    _detail('反馈渠道', '未配置反馈提交服务或官方联系方式，当前无法在应用内提交反馈。'),
  ], page: true);

  void _showAbout() => _showPanel('关于智序 (SmartOrder)', [
    _detail('应用', '智序 AI 工作台'),
    _detail('真实项目版本', '1.0.0+1'),
    _detail('参考设计版本', 'v2.4.0 最新（仅示例，不代表实际版本或有可用升级）'),
    const Text(
      '个人档案、周报、Pro、平台状态及缓存占用为设计示例。AI、云端同步、平台授权、会员验证与反馈服务尚未接入；此页不展示未经核实的备案号。',
    ),
  ], page: true);

  Future<void> _confirmLogout() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: '退出登录 / 切换账号',
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('确定要退出当前账号吗？将清除本地登录凭据并返回登录页，可在那里登录其他账号。当前未接入云端会话注销服务。'),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(secureStorageProvider).clear();
    } catch (_) {
      if (!mounted) return;
      _showPanel('退出未完成', [const Text('未能清除本地登录凭据，请稍后重试。尚未执行云端注销或跳转登录。')]);
      return;
    }
    if (!mounted) return;
    context.go(RouteNames.auth);
  }
}

class _ProTag extends StatelessWidget {
  const _ProTag();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFEADDFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Text(
      'Pro',
      style: TextStyle(
        fontSize: 10,
        color: Color(0xFF712AE2),
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
