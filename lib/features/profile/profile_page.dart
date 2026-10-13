import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/route_names.dart';
import '../../app/theme/app_colors.dart';
import '../../core/storage/secure_storage.dart';
import '../shared/main_bottom_nav.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _reminders = true;
  bool _autoSchedule = true;
  String _focusWindow = '09:00 - 22:00';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        title: const Row(
          children: [
            Text('智序', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(width: 8),
            _ProTag(),
          ],
        ),
        actions: [
          IconButton(onPressed: _showSync, icon: const Icon(Icons.sync)),
          IconButton(
            onPressed: _showAi,
            icon: const Icon(Icons.auto_awesome, color: AppColors.primary),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _card(
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: const Color(0xFFDBE1FF),
                      child: const Icon(
                        Icons.person,
                        size: 34,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '林知序',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '高级产品设计专家 · 考研备考中',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _showProfile,
                      icon: const Icon(
                        Icons.qr_code_2_outlined,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 11,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF4FF),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFF712AE2)),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          '智序 AI Pro · 智能协同版',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _showPro,
                        child: const Text('特权管理'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.insights_outlined, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      '效能周报看板',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Spacer(),
                    Text(
                      '第43周',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _metric('38', '本周交付', '+12.5%'),
                    _metric('42.5h', '专注时长', '+8.2%'),
                    _metric('92%', '计划达成', '优秀'),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _showWeeklyReport,
                    icon: const Icon(Icons.arrow_forward, size: 16),
                    label: const Text('完整周报'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _section('偏好设置', [
            _setting(
              Icons.notifications_none,
              '智能提醒',
              '仅本页偏好，系统通知未接入',
              trailing: Switch(
                value: _reminders,
                onChanged: (value) => setState(() => _reminders = value),
              ),
            ),
            _setting(
              Icons.auto_awesome,
              'AI 自动排程',
              '仅本页偏好，AI 服务未接入',
              trailing: Switch(
                value: _autoSchedule,
                onChanged: (value) => setState(() => _autoSchedule = value),
              ),
            ),
            _setting(
              Icons.schedule,
              '专注时间',
              _focusWindow,
              onTap: _pickFocusWindow,
            ),
          ]),
          const SizedBox(height: 12),
          _section('平台与账号', [
            _setting(Icons.link, '已连接平台', '平台连接状态未接入', onTap: _showPlatforms),
            _setting(
              Icons.lock_outline,
              '账号与安全',
              '本地登录状态与安全说明',
              onTap: _showAccount,
            ),
            _setting(Icons.cloud_outlined, '数据同步', '云端同步未接入', onTap: _showSync),
          ]),
          const SizedBox(height: 12),
          _section('更多', [
            _setting(
              Icons.help_outline,
              '帮助与反馈',
              '使用说明与反馈接入状态',
              onTap: _showHelp,
            ),
            _setting(Icons.info_outline, '关于智序', '版本 1.0.0', onTap: _showAbout),
          ]),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: _confirmLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFBA1A1A),
              side: const BorderSide(color: Color(0xFFEDC4C1)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 4),
    );
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border.withValues(alpha: .5)),
    ),
    child: child,
  );
  Widget _metric(String value, String label, String delta) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delta,
            style: const TextStyle(fontSize: 10, color: Color(0xFF059669)),
          ),
        ],
      ),
    ),
  );
  Widget _section(String title, List<Widget> children) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
        ...children,
      ],
    ),
  );
  Widget _setting(
    IconData icon,
    String title,
    String subtitle, {
    Widget? trailing,
    VoidCallback? onTap,
  }) => ListTile(
    dense: true,
    leading: Icon(icon, color: AppColors.primary, size: 21),
    title: Text(
      title,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
    trailing:
        trailing ??
        const Icon(
          Icons.chevron_right,
          size: 19,
          color: AppColors.textSecondary,
        ),
    onTap: onTap,
  );

  Future<void> _pickFocusWindow() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      helpText: '选择专注开始时间',
    );
    if (time == null || !mounted) return;
    setState(() => _focusWindow = '${time.format(context)} - 22:00');
  }

  void _showPanel(String title, List<Widget> children) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detail(String title, String value) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(value),
  );

  void _showProfile() => _showPanel('个人档案', [
    _detail('姓名', '林知序'),
    _detail('职业', '高级产品设计专家'),
    _detail('当前目标', '考研备考中'),
    const Text('以上为当前页面的示例档案，未接入账号档案读取或编辑服务。'),
  ]);

  void _showPro() => _showPanel('Pro 权益信息', [
    _detail('当前展示方案', '智序 AI Pro · 智能协同版'),
    _detail('会员标识', 'Pro'),
    const Text(
      '当前为页面展示信息，未接入订阅或权益验证服务。暂无可核实的有效期、额度或订单信息，不能在此购买、续费或管理订阅。AI 服务尚未接入。',
    ),
  ]);

  void _showWeeklyReport() => _showPanel('效能周报 · 第43周', [
    _detail('本周交付', '38 · 较上周 +12.5%'),
    _detail('专注时长', '42.5h · 较上周 +8.2%'),
    _detail('计划达成', '92% · 优秀'),
    const Text('以上沿用看板中的三个示例指标，未接入真实统计或历史周报服务。'),
  ]);

  void _showPlatforms() => _showPanel('已连接平台', [
    const Text('尚未接入平台授权或连接状态查询，无法确认真实已连接的平台。原页面的“5 个平台已联通”为示例文案，并非授权结果。'),
    _detail('企业微信', '现有消息和任务示例来源；连接状态未验证'),
    _detail('学习通', '现有消息和任务示例来源；连接状态未验证'),
    _detail('钉钉', '现有消息和任务示例来源；连接状态未验证'),
    const Text('此处不提供尚未实现的连接、解绑或重新授权操作。'),
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
    _showPanel('账号与安全', [
      _detail('登录状态', status),
      _detail('凭据存储', '使用 flutter_secure_storage 安全存储；不展示令牌内容'),
      const Text(
        '项目已有手机号验证码和密码登录入口，但此页尚未接入账号资料、手机号更换、密码修改或隐私管理服务。个人档案中的姓名不代表已验证的登录账号。',
      ),
    ]);
  }

  void _showSync() => _showPanel('数据同步说明', [
    _detail('同步状态', '未接入云端同步服务'),
    _detail('最近同步时间', '暂无真实同步记录'),
    const Text(
      '此操作仅打开说明，不会上传、下载或同步数据。智能提醒、AI 自动排程和专注时间仅保存在当前页面状态中，离开页面后可能重置，未持久化，也未同步到其他设备或平台。',
    ),
  ]);

  void _showAi() => _showPanel('AI 助理 · 未接入', [
    const Text('当前未接入 AI 模型或自动排程服务。AI 自动排程开关仅用于本页偏好展示，不会生成推荐时段、调用模型或执行任务。'),
    _detail('本页排程偏好', _autoSchedule ? '开启（不执行排程）' : '关闭'),
    _detail('专注时间', _focusWindow),
  ]);

  void _showHelp() => _showPanel('帮助与反馈', [
    _detail('如何查看信息', '点击完整周报、特权管理或个人档案图标查看现有信息。底部导航可切换任务、日历和消息等页面。'),
    _detail('偏好设置是否生效', '开关及专注时间仅修改本页状态，尚未关联系统通知、AI 或云端同步。'),
    _detail('如何退出', '确认退出后清除本地安全存储中的登录凭据并返回登录页，不执行云端会话注销。'),
    _detail('反馈渠道', '未配置反馈提交服务或官方联系方式，当前无法在应用内提交反馈。'),
  ]);

  void _showAbout() => _showPanel('关于智序', [
    _detail('应用', '智序 AI 工作台'),
    _detail('项目版本', '1.0.0+1'),
    _detail('页面内容', '任务、日历、消息与个人信息工作台'),
    const Text('个人档案、周报及 Pro 信息为现有示例内容。AI、云端同步、平台授权、会员权益验证和反馈服务尚未接入。'),
  ]);

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？将清除本地登录凭据并返回登录页。当前未接入云端会话注销服务。'),
        actions: [
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
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
