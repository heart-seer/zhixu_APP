import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/domain_models.dart';
import '../shared/local_repository.dart';
import '../shared/data_providers.dart';

import '../../app/theme/app_colors.dart';
import '../shared/app_card.dart';
import '../shared/app_presentation.dart';
import '../shared/main_bottom_nav.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  AppRepository get _repository => ref.read(repositoryProvider);
  int get _completed => _repository.completedTaskCount;
  int get _total => _repository.tasks.length;
  Task? get _focusTask {
    final tasks = _repository.tasks.where(
      (task) => task.priority == TaskPriority.p0,
    );
    for (final task in tasks) {
      if (!task.completed) return task;
    }
    return tasks.isEmpty ? null : tasks.first;
  }

  bool _fabOpen = false;
  bool get _p0Completed => _focusTask?.completed ?? false;
  bool get _scheduled => _repository.tasks.any((task) => task.scheduled);
  bool _notificationsRead = false;
  bool _cameraParsed = false;
  String _workStatus = '深度专注中';
  final _voiceController = TextEditingController(text: '明早9点和王老师讨论毕业论文初稿');
  final _pasteController = TextEditingController(
    text: '【项目组通知】请于本周四下午5点前完成Q3季度OKR自评表格，周五上午10点线上总结。',
  );
  String _parsedTitle = '与王老师讨论毕业论文初稿';

  int get _percent => _total == 0 ? 0 : (_completed * 100 / _total).round();

  @override
  void dispose() {
    _voiceController.dispose();
    _pasteController.dispose();
    super.dispose();
  }

  Future<void> _sheet(
    String title,
    Widget content, {
    bool asPage = false,
  }) async {
    if (!mounted) return;
    if (asPage) {
      await pushAppPage<void>(context: context, title: title, child: content);
    } else {
      await showAppDialog<void>(context: context, title: title, child: content);
    }
  }

  void _closeQuickMenu() {
    if (_fabOpen) setState(() => _fabOpen = false);
  }

  void _openQuickMenuAction(VoidCallback action) {
    _closeQuickMenu();
    action();
  }

  Widget _button(
    String label,
    VoidCallback onPressed, {
    bool primary = false,
  }) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: primary ? AppColors.primary : const Color(0xFFEFF4FF),
      foregroundColor: primary ? Colors.white : const Color(0xFF434655),
    ),
    child: Text(label),
  );

  void _showProfile() => _sheet(
    '晨曦 (Chenxi)',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('[邮箱] · Pro 会员'),
        const SizedBox(height: 16),
        const Text('当前工作状态模式：'),
        Wrap(
          spacing: 8,
          children: ['深度专注', '常规协作', '休假勿扰']
              .map(
                (value) => ActionChip(
                  label: Text(value),
                  onPressed: () {
                    setState(() => _workStatus = value);
                    Navigator.pop(context);
                  },
                ),
              )
              .toList(),
        ),
      ],
    ),
  );

  void _showNotifications() => _sheet(
    '通知中心',
    StatefulBuilder(
      builder: (context, refresh) => Column(
        children: [
          const ListTile(
            leading: Icon(Icons.auto_awesome, color: AppColors.primary),
            title: Text('Copilot 智能调度建议'),
            subtitle: Text('已避让 15:00 冲突会议并生成最优番茄钟'),
            trailing: Text('10分钟前'),
          ),
          const ListTile(
            leading: Icon(Icons.alarm, color: AppColors.primary),
            title: Text('急件提醒：期中复习测验'),
            subtitle: Text('距离计算机网络测验提交仅剩约 2 小时'),
            trailing: Text('35分钟前'),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _notificationsRead
                  ? null
                  : () {
                      if (!mounted) return;
                      setState(() => _notificationsRead = true);
                      refresh(() {});
                    },
              child: Text(_notificationsRead ? '已全部读完' : '全部已读'),
            ),
          ),
        ],
      ),
    ),
    asPage: true,
  );

  void _showAi() => _sheet(
    '智序 AI 效能助手',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _InfoBox('当前展示本地任务数据，尚未接入 AI 服务；不能提交指令或生成智能诊断。'),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('重新平衡排程'),
              onPressed: () {
                Navigator.pop(context);
                _autoSchedule();
              },
            ),
            ActionChip(
              label: const Text('效能深度诊断'),
              onPressed: () {
                Navigator.pop(context);
                _showDetail(
                  '今日效能数据',
                  '本地已完成 $_completed / $_total 项，目标达成 $_percent%。\n页面示例专注时长：3.8h。\n尚未接入 AI 诊断服务。',
                );
              },
            ),
          ],
        ),
        TextField(
          decoration: InputDecoration(
            hintText: '向智序 AI 提问或吩咐任务...',
            suffixIcon: IconButton(
              icon: const Icon(Icons.send),
              onPressed: () {
                Navigator.pop(context);
                _showDetail('AI 服务未接入', '当前未连接 AI 服务，输入内容未发送。可使用本地任务与日程面板。');
              },
            ),
          ),
        ),
      ],
    ),
  );

  void _showCamera() => _sheet(
    '拍照智能识别',
    StatefulBuilder(
      builder: (context, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              refresh(() => _cameraParsed = true);
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                border: Border.all(color: const Color(0xFFC3C6D7)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add_a_photo, color: AppColors.primary, size: 36),
                  SizedBox(height: 8),
                  Text('点击模拟拍照或选择试卷/黑板板书'),
                  Text('支持识别手写作业、课表、日程纪要', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
          const _InfoBox('当前为本地拍照示例，尚未接入相机、图片选择或 AI 识别服务。'),
          if (_cameraParsed)
            const _InfoBox('示例待办：《操作系统》第五章进程调度算法习题，建议本周五 20:00 前完成。'),
          Row(
            children: [
              Expanded(child: _button('取消', () => Navigator.pop(context))),
              const SizedBox(width: 8),
              Expanded(
                child: _button('确定加入待办', () {
                  if (!_cameraParsed) {
                    showAppDialog<void>(
                      context: context,
                      title: '尚未识别图片',
                      child: const Text('请先拍照或选择图片。当前仅提供本地示例，不会调用相机或 OCR 服务。'),
                    );
                    return;
                  }
                  _addTask('《操作系统》第五章进程调度算法习题');
                  Navigator.pop(context);
                }, primary: true),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _showVoice() => _sheet(
    '自然语音/文本排程',
    StatefulBuilder(
      builder: (context, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _voiceController,
            onChanged: (value) => refresh(() => _parsedTitle = value),
            decoration: InputDecoration(
              hintText: '例如：明天下午两点去图书馆交报告',
              suffixIcon: IconButton(
                icon: const Icon(Icons.mic),
                onPressed: () {
                  _showDetail(
                    '语音服务未接入',
                    '当前未接入麦克风录音或语音识别服务。请在文本框输入任务，或选择下方本地示例。',
                  );
                },
              ),
            ),
          ),
          Wrap(
            spacing: 6,
            children: ['明早9点和王老师讨论毕业论文初稿', '周五晚上八点交微积分大作业']
                .map(
                  (value) => ActionChip(
                    label: Text(value),
                    onPressed: () {
                      _voiceController.text = value;
                      refresh(() => _parsedTitle = value);
                    },
                  ),
                )
                .toList(),
          ),
          _InfoBox('待办：$_parsedTitle\n时间：明日 09:00 - 10:00 · 地点：导师办公室'),
          _button('确认加入日程', () {
            final title = _voiceController.text.trim();
            if (title.isEmpty) return;
            final task = _addTask(title);
            final now = DateTime.now();
            _repository.scheduleTask(
              taskId: task.id,
              start: DateTime(now.year, now.month, now.day + 1, 9),
              duration: const Duration(hours: 1),
            );
            Navigator.pop(context);
          }, primary: true),
        ],
      ),
    ),
  );

  void _showPaste() => _sheet(
    '长文本智能待办提取',
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pasteController,
          maxLines: 4,
          decoration: const InputDecoration(hintText: '粘贴微信聊天记录、群公告、会议记录等...'),
        ),
        const _InfoBox('已提取待办：Q3季度OKR自评填报（周四17:00前）；线上总结复盘会（周五10:00）'),
        _button('导入全部待办', () {
          final text = _pasteController.text.trim();
          if (text.isEmpty) return;
          _addTask(text);
          Navigator.pop(context);
        }, primary: true),
      ],
    ),
  );

  void _showP0() {
    final task = _focusTask;
    if (task == null) return;
    _sheet(
      task.title,
      StatefulBuilder(
        builder: (context, refresh) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoBox(_deadlineStatus(task.id, '待安排')),
            Text(task.description),
            for (final step in task.steps)
              CheckboxListTile(
                value: step.completed,
                onChanged: (value) {
                  _repository.setStepCompleted(
                    task.id,
                    step.id,
                    value ?? false,
                  );
                  refresh(() {});
                },
                title: Text(step.title),
              ),
            _button(task.completed ? '恢复待办' : '标记完成', () {
              _repository.toggleTask(task.id);
              refresh(() {});
            }),
          ],
        ),
      ),
      asPage: true,
    );
  }

  void _toggleP0() {
    if (!mounted) return;
    final task = _focusTask;
    if (task != null) _repository.toggleTask(task.id);
  }

  Task _addTask(String title) {
    final task = Task(
      id: _repository.newId('task'),
      title: title,
      platform: '个人自主',
      group: '本周待办列表',
      priority: TaskPriority.normal,
      estimate: const Duration(hours: 1),
    );
    _repository.addTask(task);
    return task;
  }

  String _deadlineStatus(String id, String fallback) {
    final task = _repository.taskById(id);
    if (task == null) return fallback;
    if (task.completed) return '已完成';
    final due = task.dueAt;
    return due == null
        ? '待安排'
        : '${due.month}月${due.day}日 ${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')} 截止';
  }

  void _showAllDeadlines() => _sheet(
    '全部近期动态',
    StatefulBuilder(
      builder: (context, refresh) {
        return Column(
          children: _repository.tasks
              .map(
                (task) => ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.platform} · ${_deadlineStatus(task.id, '待安排')}',
                  ),
                  onTap: () async {
                    await _openQuick(task);
                    if (context.mounted) refresh(() {});
                  },
                ),
              )
              .toList(),
        );
      },
    ),
    asPage: true,
  );

  Future<void> _openQuick(Task task) => _sheet(
    task.title,
    StatefulBuilder(
      builder: (context, refresh) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${task.platform} · ${_deadlineStatus(task.id, '待安排')}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(task.description),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: [
              ActionChip(
                label: const Text('推迟 1 小时'),
                onPressed: () {
                  if (!mounted) return;
                  _repository.delayTask(task.id, const Duration(hours: 1));
                  refresh(() {});
                },
              ),
              ActionChip(
                label: const Text('查看来源 App'),
                onPressed: () {
                  _showDetail(
                    '${task.platform} 来源信息',
                    '${task.title}\n${task.description}\n\n当前仅展示本地内容，未连接来源 App。',
                  );
                },
              ),
              ActionChip(
                label: Text(task.completed ? '已完成' : '标记已完成'),
                onPressed: () {
                  if (!mounted || task.completed) return;
                  _repository.toggleTask(task.id);
                  refresh(() {});
                },
              ),
            ],
          ),
        ],
      ),
    ),
    asPage: true,
  );

  void _autoSchedule() {
    final now = DateTime.now();
    var start = DateTime(now.year, now.month, now.day + 1, 9);
    for (final task in _repository.tasks.where(
      (task) => !task.completed && !task.scheduled,
    )) {
      final duration = task.estimate ?? const Duration(hours: 1);
      _repository.scheduleTask(
        taskId: task.id,
        start: start,
        duration: duration,
      );
      start = start.add(duration);
    }
    _showDetail(
      '本地排程建议',
      '未完成且未排程的任务已按预估时长依次安排到明日 09:00 起，可在日历查看。\n\n这是本地顺序排程，未计算冲突或最优时段，未接入 AI 或外部日历。',
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(repositoryProvider);
    final percent = _percent;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _fabOpen
                      ? () => setState(() => _fabOpen = false)
                      : null,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        toolbarHeight: 64,
                        backgroundColor: const Color(0xFFF8F9FF),
                        surfaceTintColor: Colors.transparent,
                        titleSpacing: 16,
                        title: GestureDetector(
                          onTap: _showProfile,
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Color(0xFFEDE8FF),
                                  child: Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF4A4C56),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                '智序',
                                style: TextStyle(
                                  color: Color(0xFF0B1C30),
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 8),
                              _Tag('Pro'),
                            ],
                          ),
                        ),
                        actions: [
                          IconButton(
                            onPressed: _showNotifications,
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 26,
                                ),
                                if (!_notificationsRead)
                                  const Positioned(
                                    right: -1,
                                    top: -1,
                                    child: _Dot(),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_outlined,
                                            size: 15,
                                            color: Color(0xFF9A7A37),
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '10月24日 星期四 · 农历九月廿二',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF737686),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              '早上好，晨曦',
                                              style: TextStyle(
                                                fontSize: 23,
                                                fontWeight: FontWeight.w800,
                                                height: 1.15,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(
                                            Icons.wb_sunny_rounded,
                                            size: 17,
                                            color: Color(0xFFF7B640),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: _showProfile,
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      maxWidth: 124,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4FF),
                                      border: Border.all(
                                        color: const Color(0xFFDCE5F8),
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: Color(0xFF6595E8),
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            _workStatus,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFF2467C9),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _efficiencyCard(percent),
                            const SizedBox(height: 12),
                            _copilotCard(),
                            const SizedBox(height: 12),
                            _p0Card(),
                            const SizedBox(height: 12),
                            _deadlines(),
                            const SizedBox(height: 12),
                            _timeline(),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fabOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () => setState(() => _fabOpen = false),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 78,
              child: GestureDetector(
                onTap: () {},
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: _fabOpen
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                width: 216,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _FabAction(
                                      label: '拍照识别作业与笔记',
                                      icon: Icons.photo_camera,
                                      onTap: () =>
                                          _openQuickMenuAction(_showCamera),
                                    ),
                                    const SizedBox(height: 8),
                                    _FabAction(
                                      label: '自然语音一句话排程',
                                      icon: Icons.mic,
                                      onTap: () =>
                                          _openQuickMenuAction(_showVoice),
                                    ),
                                    const SizedBox(height: 8),
                                    _FabAction(
                                      label: '粘贴企微/微信长文本',
                                      icon: Icons.content_paste,
                                      onTap: () =>
                                          _openQuickMenuAction(_showPaste),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8634F4), Color(0xFF174AD8)],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x33712AE2),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => setState(() => _fabOpen = !_fabOpen),
                        icon: Icon(
                          _fabOpen ? Icons.close : Icons.auto_awesome,
                          size: 19,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _fabOpen ? '收起菜单' : '智能速记',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (!_fabOpen) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.add, size: 18),
                            ],
                          ],
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 13,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MainBottomNav(selectedIndex: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _efficiencyCard(int percent) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.query_stats,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  '今日效能分析',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '目标达成 $percent%',
                style: const TextStyle(fontSize: 12, color: Color(0xFF737686)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE9ECF5)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox.expand(
                                child: CircularProgressIndicator(
                                  value: (percent / 100).clamp(0.0, 1.0),
                                  strokeWidth: 6,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: const Color(0xFFDCE9FF),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '$_completed',
                                        style: const TextStyle(
                                          fontSize: 23,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                      Text(
                                        '/$_total',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF737686),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Text(
                                    '已完成项',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF737686),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          '专注时长暂无记录',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF434655),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '进度负载',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF737686),
                              ),
                            ),
                          ),
                          Text(
                            percent >= 80
                                ? '卓越 · 超前达成'
                                : percent >= 60
                                ? '良好 · 稳步推进'
                                : '有待追赶 · 需聚焦',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: percent < 60
                                  ? const Color(0xFFBA1A1A)
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (percent / 100).clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor: const Color(0xFFDCE9FF),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _EfficiencyTip(
                          remaining: (_total - _completed).clamp(0, _total),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _copilotCard() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF7925E8), Color(0xFF5420C9), Color(0xFF326AF3)],
      ),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                '智序 Copilot 协同决策',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_repository.pendingMessageCount} 条待确认消息',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _Insight(
          icon: Icons.forum_outlined,
          text: '共享待办中还有 ${_total - _completed} 项未完成，可按预估时长进行本地排程。',
          onTap: _showAllDeadlines,
        ),
        const SizedBox(height: 6),
        _Insight(
          icon: Icons.notifications_active_outlined,
          text: '今日共有 ${_todayEvents.length} 项本地日程，任务排程后会同步出现在日历。',
          onTap: () => _showDetail(
            '今日日程',
            _todayEvents
                .map((event) => '${_time(event.start)} ${event.title}')
                .join('\n'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: TextButton(
                onPressed: _autoSchedule,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _scheduled ? '查看本地排程建议' : '一键智能自动排程',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _scheduled ? Icons.done_all : Icons.arrow_forward,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '本地顺序排程 · 非 AI',
                textAlign: TextAlign.right,
                style: TextStyle(color: Color(0xFFCFD5FF), fontSize: 9),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  void _showDetail(String title, String body) => _sheet(title, _InfoBox(body));

  Widget _p0Card() => _focusTask == null
      ? const _InfoBox('暂无 P0 任务')
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _AlarmDot(),
                const SizedBox(width: 7),
                const Expanded(
                  child: Text(
                    '紧急聚焦 · P0 任务',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  _deadlineStatus(_focusTask!.id, '待安排'),
                  style: TextStyle(color: Color(0xFFBA1A1A), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF0C8C8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A0B1C30),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: 4,
                        color: _p0Completed
                            ? const Color(0xFFC3C6D7)
                            : const Color(0xFFBA1A1A),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 10, 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDE1DF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'P0 紧急',
                                      style: TextStyle(
                                        color: Color(0xFFB42323),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F1F5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _focusTask!.platform,
                                      style: TextStyle(
                                        color: Color(0xFF455A83),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFBE9E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: _toggleP0,
                                      icon: const Icon(
                                        Icons.flag_outlined,
                                        size: 20,
                                        color: Color(0xFFBA1A1A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _focusTask!.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101B2C),
                                  decoration: _p0Completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _focusTask!.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.35,
                                  color: Color(0xFF747985),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE9EAEE),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.alarm_outlined,
                                    color: Color(0xFFCF3434),
                                    size: 21,
                                  ),
                                  const SizedBox(width: 7),
                                  Expanded(
                                    child: Text(
                                      _deadlineStatus(_focusTask!.id, '待安排'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF777B86),
                                      ),
                                    ),
                                  ),
                                  FilledButton.icon(
                                    onPressed: _showP0,
                                    icon: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      '开始微聚焦',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFFBF1717),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 7,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

  Widget _deadlines() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              '即将截止 · 近期动态',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18283D),
              ),
            ),
          ),
          TextButton(
            onPressed: _showAllDeadlines,
            child: const Text(
              '查看全部 ›',
              style: TextStyle(fontSize: 14, color: Color(0xFF1764D2)),
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 140,
        child: ListView(
          padding: EdgeInsets.zero,
          scrollDirection: Axis.horizontal,
          children: [
            for (final task in _upcomingTasks.take(3))
              _DeadlineCard(
                title: task.title,
                tag: task.platform,
                time: _deadlineStatus(task.id, '待安排'),
                description: task.description,
                onTap: () => _openQuick(task),
              ),
            if (_upcomingTasks.isEmpty) const Center(child: Text('暂无待办任务')),
          ],
        ),
      ),
    ],
  );

  List<Task> get _upcomingTasks =>
      _repository.tasks.where((task) => !task.completed).toList()..sort((a, b) {
        if (a.dueAt == null) return b.dueAt == null ? 0 : 1;
        if (b.dueAt == null) return -1;
        return a.dueAt!.compareTo(b.dueAt!);
      });

  List<CalendarEvent> get _todayEvents => _repository.eventsOn(DateTime.now());
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Widget _timeline() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Expanded(
            child: Text(
              '今日日程时间线',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const Text(
            '按时间顺序流转',
            style: TextStyle(fontSize: 10, color: Color(0xFF858A98)),
          ),
        ],
      ),
      const SizedBox(height: 8),
      _Card(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          children: [
            for (final entry in _todayEvents.asMap().entries)
              _TimelineItem(
                time: '${_time(entry.value.start)}–${_time(entry.value.end)}',
                status: entry.value.completed ? '已完成' : '待处理',
                title: entry.value.title,
                description: entry.value.subtitle,
                done: entry.value.completed,
                isFirst: entry.key == 0,
                isLast: entry.key == _todayEvents.length - 1,
              ),
            if (_todayEvents.isEmpty) const Text('今日暂无日程'),
          ],
        ),
      ),
    ],
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)})
    : borderColor = const Color(0xFFC3C6D7);
  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: borderColor.withValues(alpha: .3)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0B1C30),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _EfficiencyTip extends StatelessWidget {
  const _EfficiencyTip({required this.remaining});
  final int remaining;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF4FF),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFD5E2FF)),
    ),
    child: Text.rich(
      TextSpan(
        style: const TextStyle(
          fontSize: 12,
          height: 1.55,
          fontWeight: FontWeight.w500,
          color: Color(0xFF28364D),
        ),
        children: [
          const TextSpan(
            text: '💡 智能提示：',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '今日核心任务尚余 '),
          TextSpan(
            text: '$remaining 项',
            style: const TextStyle(
              color: Color(0xFFE24B4B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: '，建议优先处理高优先级任务。'),
        ],
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _InfoBox extends StatelessWidget {
  const _InfoBox(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(vertical: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEFF4FF),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: const TextStyle(fontSize: 13, height: 1.45)),
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFE5EEFF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: const BoxDecoration(
      color: Color(0xFFBA1A1A),
      shape: BoxShape.circle,
    ),
  );
}

class _AlarmDot extends StatefulWidget {
  const _AlarmDot();

  @override
  State<_AlarmDot> createState() => _AlarmDotState();
}

class _AlarmDotState extends State<_AlarmDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Opacity(
      opacity: .45 + _controller.value * .55,
      child: Transform.scale(
        scale: .82 + _controller.value * .28,
        child: child,
      ),
    ),
    child: Container(
      width: 9,
      height: 9,
      decoration: const BoxDecoration(
        color: Color(0xFFBA1A1A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Color(0x55BA1A1A), blurRadius: 5, spreadRadius: 1),
        ],
      ),
    ),
  );
}

class _FabAction extends StatelessWidget {
  const _FabAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 4,
    borderRadius: BorderRadius.circular(28),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFE5EEFF),
              child: Icon(icon, size: 16, color: AppColors.primary),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Insight extends StatelessWidget {
  const _Insight({required this.text, required this.icon, required this.onTap});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF17245C).withValues(alpha: .24),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE7DCFF), size: 15),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({
    required this.title,
    required this.tag,
    required this.time,
    required this.description,
    required this.onTap,
    this.secondary,
    this.onSecondary,
  });
  final String title, tag, time, description;
  final VoidCallback onTap;
  final String? secondary;
  final VoidCallback? onSecondary;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: (MediaQuery.sizeOf(context).width * .62).clamp(190.0, 250.0),
      margin: const EdgeInsets.only(right: 12),
      child: AppAccentCard(
        accentColor: tag == '企微待办'
            ? const Color(0xFFA66B00)
            : AppColors.primary,
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        borderColor: const Color(0xFFE3E7F0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080B1C30),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.stretch,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: tag == '企微待办'
                        ? const Color(0xFFFFE9C5)
                        : const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag == '企微待办' ? '企微待办' : tag,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: tag == '企微待办'
                          ? const Color(0xFF825500)
                          : AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A6A2C),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Color(0xFF737686)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: secondary == null
                      ? const Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Color(0xFF8A8D99),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '协同: 王工',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8D99),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Icon(
                              Icons.videocam_outlined,
                              size: 15,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '45分钟',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF8A8D99),
                              ),
                            ),
                          ],
                        ),
                ),
                if (secondary == null)
                  const Icon(
                    Icons.radio_button_unchecked,
                    size: 18,
                    color: AppColors.primary,
                  )
                else
                  TextButton(onPressed: onSecondary, child: Text(secondary!)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.time,
    required this.status,
    required this.title,
    required this.description,
    this.done = false,
    this.active = false,
    this.onFocus,
    this.onMaterials,
    this.isFirst = false,
    this.isLast = false,
  });
  final String time, status, title, description;
  final bool done, active, isFirst, isLast;
  final VoidCallback? onFocus, onMaterials;

  @override
  Widget build(BuildContext context) {
    final color = active || done
        ? const Color(0xFF245EDB)
        : const Color(0xFF828899);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: isFirst ? 8 : 0,
                  bottom: isLast ? 24 : 0,
                  child: Container(width: 1, color: const Color(0xFFE1E8F7)),
                ),
                Positioned(
                  top: active ? 16 : 5,
                  child: Container(
                    width: active ? 20 : 16,
                    height: active ? 20 : 16,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEAF1FF) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active || done
                            ? const Color(0xFF245EDB)
                            : const Color(0xFF858A98),
                        width: active ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: done ? color : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: active
                  ? const EdgeInsets.fromLTRB(12, 10, 10, 8)
                  : const EdgeInsets.fromLTRB(0, 5, 0, 5),
              decoration: active
                  ? BoxDecoration(
                      color: const Color(0xFFEFF4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .2),
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        flex: 4,
                        child: Text(
                          time,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: active || done
                                ? const Color(0xFF245EDB)
                                : const Color(0xFF0B1C30),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : const Color(0xFFF0F2F7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? Colors.white
                                : const Color(0xFF818696),
                          ),
                        ),
                      ),
                      if (active) const Spacer(),
                      if (active)
                        const Text(
                          '剩余 45m',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (done) const Spacer(),
                      if (done)
                        const Icon(
                          Icons.check_circle,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      if (!done && !active && isLast) const Spacer(),
                      if (!done && !active && isLast)
                        const Icon(
                          Icons.access_time_rounded,
                          size: 19,
                          color: Color(0xFF8D93A1),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? const Color(0xFF737686) : null,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF737686),
                    ),
                  ),
                  if (active)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        FilledButton.icon(
                          onPressed: onFocus,
                          style: FilledButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          icon: const Icon(Icons.timer_outlined, size: 13),
                          label: const Text(
                            '开启番茄专注',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: onMaterials,
                          style: OutlinedButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: const Color(0xFF434655),
                            side: const BorderSide(color: Color(0xFFE2E6EF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          child: const Text(
                            '查看资料',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
