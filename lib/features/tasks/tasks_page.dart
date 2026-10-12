import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../shared/main_bottom_nav.dart';

class _TaskItem {
  _TaskItem({required this.title, required this.platform, required this.group, required this.due, required this.priority, this.estimate, this.description = '', this.completed = false, this.steps = const []});
  final String title;
  final String platform;
  final String group;
  final String due;
  final String priority;
  final String? estimate;
  final String description;
  final List<String> steps;
  bool completed;
  bool scheduled = false;
}

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _searchController = TextEditingController();
  final _tasks = <_TaskItem>[
    _TaskItem(title: '完成数据结构实验报告', platform: '学习通', group: '即将截止 / P0 紧急', due: '周五 22:00 截止 · 剩余 2天', priority: '高优先级 P0', estimate: '预估 3小时', steps: ['红黑树插入与平衡旋转算法实现代码整理', '绘制算法性能对比折线图 (Gnuplot / Excel)', '撰写实验结论与空间复杂度差异分析', '导出 PDF 格式并提交至学习通系统']),
    _TaskItem(title: '提交敏捷研发组 Q3 阶段总结周报', platform: '企业微信', group: '即将截止 / P0 紧急', due: '明天 18:00 截止 · 剩余 20小时', priority: 'P0 紧急', estimate: '预估 45分'),
    _TaskItem(title: '分布式高并发系统架构拓扑图绘制', platform: '个人自主', group: '今日进行中', due: '今日日程已占用：15:00 - 16:30', priority: '进行中 · 耗时 1.5h', description: '已完成网关与鉴权模块，待补全 Redis 缓存集群同步流向。'),
    _TaskItem(title: '计算机体系结构期中重点知识点复习', platform: '学习通', group: '今日进行中', due: '进度 2/5 核心卡片', priority: '第 4 章节流水线冲突'),
    _TaskItem(title: '研究生组会文献 PPT 预讲', platform: '钉钉', group: '本周待办列表', due: '周日 19:00 · 预计 2.0h', priority: '普通'),
    _TaskItem(title: '发送导师周报抄送知悉', platform: '企业微信', group: '本周待办列表', due: '已于今日 11:20 提早完成', priority: '已完成', completed: true),
  ];
  final Map<_TaskItem, Set<String>> _doneSteps = {};
  String _filter = '全部';
  bool _searchOpen = false;
  bool _gridView = false;
  bool _batchScheduled = false;
  String _createPlatform = '学习通';
  int _createPriority = 0;
  int _createEstimate = 1;
  final _newTaskController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _newTaskController.dispose();
    super.dispose();
  }

  List<_TaskItem> get _filtered => _tasks.where((task) {
    final platformMatches = _filter == '全部' || task.platform == _filter;
    final q = _searchController.text.trim().toLowerCase();
    return platformMatches && (q.isEmpty || task.title.toLowerCase().contains(q) || task.platform.toLowerCase().contains(q));
  }).toList();

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));

  void _sheet(String title, Widget child) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(top: false, child: Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close))]),
        const Divider(height: 1),
        Flexible(child: SingleChildScrollView(child: child)),
      ]),
    )),
  );

  @override
  Widget build(BuildContext context) {
    final visible = _filtered;
    final groups = ['即将截止 / P0 紧急', '今日进行中', '本周待办列表'];
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(bottom: false, child: Column(children: [
        Material(color: const Color(0xFFF8F9FF), elevation: 1, child: Column(children: [
          SizedBox(height: 56, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
            CircleAvatar(radius: 17, backgroundColor: const Color(0xFFE5EEFF), child: Icon(Icons.person, color: AppColors.primary, size: 20)),
            const SizedBox(width: 10),
            const Text('智序', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEADDFF), borderRadius: BorderRadius.circular(20)), child: const Text('任务中心', style: TextStyle(fontSize: 11, color: Color(0xFF5A00C6), fontWeight: FontWeight.w600))),
            const Spacer(),
            IconButton(onPressed: () => setState(() { _searchOpen = !_searchOpen; if (!_searchOpen) _searchController.clear(); }), icon: Icon(_searchOpen ? Icons.close : Icons.search)),
            IconButton(onPressed: _showCreateTask, icon: const Icon(Icons.auto_awesome, color: Color(0xFF712AE2))),
          ]))),
          if (_searchOpen) Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 8), child: TextField(controller: _searchController, onChanged: (_) => setState(() {}), decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: '搜索任务名称、标签或平台...', suffixIcon: IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.border))))),
          SizedBox(
            height: 56,
            child: Row(children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: ['全部', '学习通', '企业微信', '钉钉', '个人自主']
                        .map((item) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: _filterChip(item),
                            ))
                        .toList(),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF0F1F8), borderRadius: BorderRadius.circular(13)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _viewToggle(Icons.format_list_bulleted, !_gridView, () => setState(() => _gridView = false)),
                  _viewToggle(Icons.grid_view, _gridView, () => setState(() => _gridView = true)),
                ]),
              ),
            ]),
          ),
        ])),
        Expanded(child: visible.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.inbox_outlined, size: 48, color: AppColors.border), SizedBox(height: 8), Text('暂无匹配任务'), Text('换个筛选关键词或平台看看吧', style: TextStyle(color: AppColors.textSecondary))]))
          : ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 110), children: [
            _aiScheduleCard(),
            const SizedBox(height: 20),
            ...groups.map((group) {
              final tasks = visible.where((task) => task.group == group).toList();
              if (tasks.isEmpty) return const SizedBox.shrink();
              return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4), child: Row(children: [Icon(Icons.circle, size: 9, color: group.startsWith('即将') ? AppColors.error : group == '今日进行中' ? AppColors.primary : AppColors.textSecondary), const SizedBox(width: 8), Expanded(child: Text(group, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: group.startsWith('即将') ? const Color(0xFFFFE6E3) : const Color(0xFFE9ECF4), borderRadius: BorderRadius.circular(18)), child: Text('${tasks.length}项${group.startsWith('即将') ? '紧迫' : ''}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: group.startsWith('即将') ? AppColors.error : AppColors.textSecondary)))])),
                if (_gridView)
                  Wrap(spacing: 10, runSpacing: 10, children: tasks.map(_gridTaskCard).toList())
                else
                  ...tasks.map((task) => Padding(padding: const EdgeInsets.only(top: 8), child: _taskCard(task))),
              ]));
            }),
          ])),
      ])),
      floatingActionButton: FloatingActionButton(onPressed: _showCreateTask, backgroundColor: const Color(0xFF712AE2), foregroundColor: Colors.white, child: const Icon(Icons.add)),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 1),
    );
  }

  Widget _viewToggle(IconData icon, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: selected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, size: 19, color: selected ? AppColors.primary : AppColors.textSecondary),
        ),
      );

  Widget _filterChip(String item) {
    final selected = _filter == item;
    final count = item == '全部' ? _tasks.length : _tasks.where((task) => task.platform == item).length;
    final dotColor = switch (item) {
      '学习通' => const Color(0xFF0757D5),
      '企业微信' => const Color(0xFF7628E8),
      '钉钉' => const Color(0xFF1688E8),
      _ => const Color(0xFF5A6070),
    };
    return InkWell(
      onTap: () => setState(() => _filter = item),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 34,
        padding: EdgeInsets.symmetric(horizontal: item == '全部' ? 12 : 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0757D5) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? const Color(0xFF0757D5) : const Color(0xFFE5E8EF)),
          boxShadow: selected ? const [BoxShadow(color: Color(0x180057D5), blurRadius: 4, offset: Offset(0, 1))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (item != '全部') ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          Text(item == '全部' ? '$item $count' : '$item ($count)', style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? Colors.white : const Color(0xFF434655))),
        ]),
      ),
    );
  }

  Widget _aiScheduleCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF6EEFF), Color(0xFFF0F5FF)]), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFDCCBFF))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Container(width: 40, height: 40, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF712AE2), Color(0xFF2563EB)]), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.auto_awesome, color: Colors.white, size: 23)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Row(children: [Text(_batchScheduled ? '日程编排已完成' : 'AI 待排期待办', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEADDFF), borderRadius: BorderRadius.circular(20)), child: Text(_batchScheduled ? '已就绪' : '3 项待排', style: const TextStyle(fontSize: 10, color: Color(0xFF5A00C6), fontWeight: FontWeight.w700)))]), const SizedBox(height: 2), Text(_batchScheduled ? '全部跨平台待办已成功写入系统日历与工作日程' : '检测到跨平台 3 个高优先级任务尚未入历', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.2))]) )]),
      if (!_batchScheduled) ...[
        const SizedBox(height: 14),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(12)), child: const Column(children: [
          _PreviewLine('数据结构实验报告 · 预留周四 19:30-22:30', '3.0h'),
         SizedBox(height: 2),
          _PreviewLine('企微 Q3 复盘周报初稿 · 明早 09:00', '1.5h'),
        ])),
      ] else ...[
        const SizedBox(height: 10),
        const Row(children: [Icon(Icons.task_alt, color: AppColors.primary, size: 17), SizedBox(width: 6), Expanded(child: Text('时隙冲突已检查，提醒已开启', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)))]),
      ],
      const SizedBox(height: 9),
      Row(children: [const Expanded(child: Row(children: [Icon(Icons.event_note_outlined, size: 14, color: AppColors.textSecondary), SizedBox(width: 5), Text('已根据空闲时隙智能匹配', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))])), FilledButton.icon(onPressed: _batchScheduled ? null : () => _showBatchSchedule(), icon: Icon(_batchScheduled ? Icons.check : Icons.bolt, size: 16), label: Text(_batchScheduled ? '已编排' : '一键排入日历'), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF712AE2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))]),
    ]),
  );

  Widget _taskCard(_TaskItem task) {
    final color = task.completed ? AppColors.textSecondary : task.group.startsWith('即将') ? AppColors.error : task.group == '今日进行中' ? AppColors.primary : AppColors.textSecondary;
    final doneSteps = _doneSteps[task] ?? const <String>{};
    final stepDone = task.steps.where(doneSteps.contains).length;
    return InkWell(onTap: () => task.steps.isNotEmpty ? _showSteps(task) : _showSchedule(task), borderRadius: BorderRadius.circular(16), child: Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(color: task.completed ? const Color(0xFFF9FAFD) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 7, offset: Offset(0, 2))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: IntrinsicHeight(child: Row(children: [ 
        Container(width: 6, color: color),
        Expanded(child: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _taskTag(
                    task.platform,
                    _platformColor(task.platform),
                    icon: task.platform == '学习通'
                        ? Icons.school_outlined
                        : task.platform == '企业微信'
                            ? Icons.chat_outlined
                            : null,
                    textColor: task.platform == '企业微信' ? const Color(0xFF4B168C) : null,
                  ),
                  _taskTag(
                    task.priority,
                    task.priority.contains('P0') ? const Color(0xFFFFDAD6) : const Color(0xFFE5EEFF),
                    textColor: task.priority.contains('P0') ? const Color(0xFFB42318) : null,
                  ),
                  if (task.estimate != null)
                    _taskTag(
                      task.estimate!,
                      const Color(0xFFE5EEFF),
                      textColor: const Color(0xFF344B70),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(onTap: () => setState(() => task.completed = !task.completed), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: task.completed ? const Color(0xFF712AE2) : Colors.white, border: Border.all(color: task.completed ? const Color(0xFF712AE2) : const Color(0xFFDDE1EB), width: 2), borderRadius: BorderRadius.circular(7)), child: task.completed ? const Icon(Icons.check, size: 15, color: Colors.white) : null)),
          ]),
          const SizedBox(height: 10),
          Text(task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, decoration: task.completed ? TextDecoration.lineThrough : null, color: task.completed ? AppColors.textSecondary : AppColors.textPrimary)),
          if (task.description.isNotEmpty) ...[const SizedBox(height: 5), Text(task.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
          const SizedBox(height: 6),
          Row(children: [Icon(Icons.timer_outlined, size: 15, color: color), const SizedBox(width: 6), Expanded(child: Text(task.due, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w600))), if (task.due.contains('截止')) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFFFE3E1), borderRadius: BorderRadius.circular(12)), child: Text('剩余 ${task.due.contains('2天') ? '2天' : '20小时'}', style: const TextStyle(fontSize: 10, color: Color(0xFFD9292F), fontWeight: FontWeight.w700)))]),
          if (task.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
          InkWell(onTap: () => _showSteps(task), borderRadius: BorderRadius.circular(11), child: Container(width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF7F0FF), borderRadius: BorderRadius.circular(11), border: Border.all(color: const Color(0xFFEADDFF))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF712AE2)), const SizedBox(width: 5), const Expanded(child: Text('已由 AI 拆解为 4 项执行步骤', style: TextStyle(fontSize: 11, color: Color(0xFF712AE2), fontWeight: FontWeight.w700))), Text('$stepDone/4', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary))]),
              const SizedBox(height: 7),
              ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: stepDone / task.steps.length, minHeight: 5, color: const Color(0xFF712AE2), backgroundColor: const Color(0xFFDCE9FF))),
              const SizedBox(height: 7),
              ...task.steps.take(2).toList().asMap().entries.map((entry) => Padding(padding: const EdgeInsets.only(top: 3), child: Row(children: [Icon((_doneSteps[task] ?? const <String>{}).contains(entry.value) ? Icons.check_circle : Icons.circle_outlined, size: 14, color: (_doneSteps[task] ?? const <String>{}).contains(entry.value) ? const Color(0xFF712AE2) : AppColors.textSecondary), const SizedBox(width: 6), Expanded(child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)))]))),
            ]))),
          ],
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF0F1F5)),
          Row(children: [
            TextButton.icon(
              onPressed: task.scheduled ? null : () => _showSchedule(task),
              icon: task.scheduled
                  ? const Icon(Icons.event_available, size: 17, color: Color(0xFF0757D5))
                  : const Icon(Icons.calendar_month, size: 18, color: Color(0xFF0757D5)),
              label: Text(task.scheduled ? '已排入日历' : '排入日历', style: const TextStyle(color: Color(0xFF0757D5), fontWeight: FontWeight.w700)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            ),
            const Spacer(),
            if (task.steps.isNotEmpty)
              TextButton(
                onPressed: () => _showSteps(task),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('查看详情与步骤', style: TextStyle(color: Color(0xFF343A46), fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: Color(0xFF343A46)),
                ]),
              ),
          ]),
        ]))),
      ]))),
    ));
  }

  Widget _gridTaskCard(_TaskItem task) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - 42) / 2,
    child: InkWell(
      onTap: () => task.steps.isNotEmpty ? _showSteps(task) : _showSchedule(task),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [_tag(task.platform, _platformColor(task.platform)), const Spacer(), IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => setState(() => task.completed = !task.completed), icon: Icon(task.completed ? Icons.check_circle : Icons.circle_outlined, color: task.completed ? AppColors.primary : AppColors.textSecondary, size: 20))]),
          const SizedBox(height: 8),
          Text(task.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, decoration: task.completed ? TextDecoration.lineThrough : null)),
          const Spacer(),
          Text(task.due, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    ),
  );

  Widget _taskTag(String text, Color color, {IconData? icon, Color? textColor}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: textColor ?? const Color(0xFF273248)),
          const SizedBox(width: 5)
        ],
        Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor ?? const Color(0xFF273248)),
        )
      ],
    ),
  );

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(7)),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Color _platformColor(String platform) => switch (platform) {
    '学习通' => const Color(0xFFDCE9FF),
    '企业微信' => const Color(0xFFEADDFF),
    '钉钉' => const Color(0xFFFFF1D9),
    _ => const Color(0xFFEFF1F7),
  };



  void _showBatchSchedule() => _sheet('AI 一键智能排入日历', Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 12),
    const Text('以下 3 项高优先级任务将根据空闲时隙排入日程：', style: TextStyle(color: AppColors.textSecondary)),
    const SizedBox(height: 12),
    const _PreviewLine('数据结构实验报告', '周四 19:30 · 3.0h'),
    const _PreviewLine('企微 Q3 复盘周报初稿', '明早 09:00 · 1.5h'),
    const _PreviewLine('计算机体系结构复习', '明日 15:30 · 1.5h'),
    const SizedBox(height: 14),
    _actionButton('确认一键编排到日程', () { Navigator.pop(context); setState(() { _batchScheduled = true; for (final task in _tasks.where((e) => !e.completed)) { task.scheduled = true; } }); _toast('已成功将任务排入日历并开启提醒'); }),
  ]));

  void _showSchedule(_TaskItem task) {
    var date = 0;
    var slot = 0;
    var reminder = true;
    _sheet('设置任务日程与提醒', StatefulBuilder(builder: (context, setSheetState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
      const SizedBox(height: 18),
      const Text('编排日期', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 0; i < 3; i++) Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: ChoiceChip(label: Text(['今天', '明天', '自定义日期'][i]), selected: date == i, onSelected: (_) async {
          if (i == 2) {
            final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)), initialDate: DateTime.now());
            if (picked == null) return;
          }
          setSheetState(() => date = i);
        }))),
      ]),
      const SizedBox(height: 14),
      const Text('时间段选择', style: TextStyle(fontWeight: FontWeight.w700)),
      RadioListTile<int>(contentPadding: EdgeInsets.zero, value: 0, groupValue: slot, onChanged: (value) => setSheetState(() => slot = value!), title: const Text('AI 推荐：19:30 - 21:00 (深度专注)', style: TextStyle(fontSize: 13)), subtitle: const Text('建议 1.5 小时')),
      RadioListTile<int>(contentPadding: EdgeInsets.zero, value: 1, groupValue: slot, onChanged: (value) => setSheetState(() => slot = value!), title: const Text('次选时段：15:30 - 17:00 (下午间隙)', style: TextStyle(fontSize: 13)), subtitle: const Text('建议 1.5 小时')),
      SwitchListTile(contentPadding: EdgeInsets.zero, value: reminder, onChanged: (value) => setSheetState(() => reminder = value), title: const Text('日程强提醒'), subtitle: const Text('提前 15 分钟发送系统推送')),
      const SizedBox(height: 8),
      _actionButton('确认排入', () { Navigator.pop(context); setState(() => task.scheduled = true); _toast(reminder ? '任务已排入日历并设置强提醒' : '任务已排入日历'); }),
    ])));
  }

  void _showSteps(_TaskItem task) => _sheet('AI 任务执行流拆解', StatefulBuilder(builder: (context, setSheetState) {
    final doneSteps = _doneSteps.putIfAbsent(task, () => <String>{});
    final checked = task.steps.where(doneSteps.contains).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${task.title} · ${task.steps.length} 个步骤', style: const TextStyle(color: Color(0xFF712AE2))),
      const SizedBox(height: 16),
      Row(children: [const Expanded(child: Text('整体完成进度', style: TextStyle(fontWeight: FontWeight.w600))), Text('$checked/${task.steps.length} (${(checked * 100 / task.steps.length).round()}%)', style: const TextStyle(color: Color(0xFF712AE2), fontWeight: FontWeight.w700))]),
      const SizedBox(height: 7),
      LinearProgressIndicator(value: checked / task.steps.length, color: const Color(0xFF712AE2), backgroundColor: const Color(0xFFDCE9FF), minHeight: 7),
      const SizedBox(height: 10),
      ...task.steps.asMap().entries.map((entry) => Card(color: Colors.white, child: CheckboxListTile(value: doneSteps.contains(entry.value), onChanged: (value) { setState(() { if (value == true) { doneSteps.add(entry.value); } else { doneSteps.remove(entry.value); } }); setSheetState(() {}); }, title: Text('${entry.key + 1}. ${entry.value}', style: TextStyle(fontSize: 13, decoration: doneSteps.contains(entry.value) ? TextDecoration.lineThrough : null)), subtitle: Text(['代码注记及测试用例运行 · 建议 45分', '测试不同规模耗时比对 · 建议 30分', '总结空间复杂度差异 · 建议 45分', '核验封面后提交 · 建议 10分'][entry.key % 4]), controlAffinity: ListTileControlAffinity.leading))),
      TextButton.icon(onPressed: () { final newStep = '自定义新增补充验证项 ${task.steps.length + 1}'; setState(() => task.steps.add(newStep)); setSheetState(() {}); }, icon: const Icon(Icons.add), label: const Text('增加自定义子步骤')),
      SizedBox(width: double.infinity, child: _actionButton('完成并同步卡片', () { Navigator.pop(context); _toast('执行步骤已同步'); })),
    ]);
  }));

  void _showCreateTask() => _sheet('新建任务与智能拆解', StatefulBuilder(builder: (context, setSheetState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('支持自然语言，AI 将自动提取时间与优先级', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    const SizedBox(height: 12),
    TextField(controller: _newTaskController, maxLines: 3, decoration: InputDecoration(hintText: '例如：明天下午三点前提交操作系统实验，需要2小时，紧急', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), suffixIcon: IconButton(onPressed: () => _toast('语音输入功能待接入'), icon: const Icon(Icons.mic)))),
    const SizedBox(height: 12),
    const Text('所属渠道 / 标签', style: TextStyle(fontWeight: FontWeight.w700)),
    Wrap(spacing: 6, children: ['学习通', '企业微信', '钉钉', '个人自主'].map((platform) => ChoiceChip(label: Text(platform), selected: _createPlatform == platform, onSelected: (_) => setSheetState(() => _createPlatform = platform))).toList()),
    Row(children: [
      Expanded(child: DropdownButtonFormField<int>(initialValue: _createPriority, decoration: const InputDecoration(labelText: '优先级'), items: const [DropdownMenuItem(value: 0, child: Text('高优先级 P0')), DropdownMenuItem(value: 1, child: Text('中优先级 P1')), DropdownMenuItem(value: 2, child: Text('低优先级 P2'))], onChanged: (v) => setSheetState(() => _createPriority = v ?? 0))),
      const SizedBox(width: 12),
      Expanded(child: DropdownButtonFormField<int>(initialValue: _createEstimate, decoration: const InputDecoration(labelText: '预估耗时'), items: const [DropdownMenuItem(value: 0, child: Text('1 小时')), DropdownMenuItem(value: 1, child: Text('2 小时')), DropdownMenuItem(value: 2, child: Text('3 小时')), DropdownMenuItem(value: 3, child: Text('45 分钟'))], onChanged: (v) => setSheetState(() => _createEstimate = v ?? 1))),
    ]),
    const SizedBox(height: 18),
    _actionButton('智能创建并排期', () { final title = _newTaskController.text.trim(); if (title.isEmpty) { _toast('请先输入任务内容'); return; } setState(() => _tasks.insert(0, _TaskItem(title: title, platform: _createPlatform, group: '本周待办列表', due: '新创建 · 待安排', priority: ['高优先级 P0', '中优先级 P1', '低优先级 P2'][_createPriority], estimate: ['1 小时', '2 小时', '3 小时', '45 分钟'][_createEstimate]))); _newTaskController.clear(); Navigator.pop(context); _toast('任务已创建，可继续安排日程'); }),
  ])));

  Widget _actionButton(String label, VoidCallback onPressed) => SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onPressed, icon: const Icon(Icons.check), label: Text(label), style: FilledButton.styleFrom(backgroundColor: const Color(0xFF712AE2), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13))));
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine(this.title, this.trailing);
  final String title;
  final String trailing;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [const Icon(Icons.circle, size: 7, color: AppColors.error), const SizedBox(width: 7), Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))), const SizedBox(width: 6), Text(trailing, style: const TextStyle(fontSize: 13, color: Color(0xFF712AE2), fontWeight: FontWeight.w700))]));
}
