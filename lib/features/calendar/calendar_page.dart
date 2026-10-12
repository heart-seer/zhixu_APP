import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../shared/main_bottom_nav.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  DateTime _selected = DateTime.now();
  int _monthOffset = 0;
  bool _monthOpen = false;
  DateTime? _hoveredDay;
  bool _focusRunning = false;
  final Set<int> _completedTasks = {0, 1};
  final TextEditingController _quickInputController = TextEditingController();

  @override
  void dispose() {
    _quickInputController.dispose();
    super.dispose();
  }

  DateTime get _month {
    final base = DateTime(_selected.year, _selected.month);
    return DateTime(base.year, base.month + _monthOffset);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = width / 375;
    final monthDays = _monthDays();
    final weekDays = List.generate(
      7,
      (index) =>
          _selected.subtract(Duration(days: (_selected.weekday % 7) - index)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72 * scale,
        backgroundColor: const Color(0xFFF7F8FF),
        titleSpacing: 16 * scale,
        title: Row(
          children: [
            Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFFE5EEFF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 21 * scale,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              '智序',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21 * scale,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 7 * scale),
            _AiPill(scale: scale),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'AI 智能排程',
            onPressed: _showAiSuggestion,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.auto_awesome,
              size: 23 * scale,
              color: AppColors.primary,
            ),
          ),
          IconButton(
            tooltip: '筛选',
            onPressed: _showFilters,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.tune_rounded,
              size: 23 * scale,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(width: 12 * scale),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          2,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          _calendarCard(monthDays, weekDays, scale),
          const SizedBox(height: 12),
          _daySummary(scale),
          const SizedBox(height: 10),
          _timeline(scale),
          const SizedBox(height: 14),
          _quickInput(scale),
          const SizedBox(height: 10),
          _aiButton(scale),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(selectedIndex: 2),
    );
  }

  Widget _calendarCard(
    List<DateTime> monthDays,
    List<DateTime> weekDays,
    double scale,
  ) {
    return _card(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        10 * scale,
        16 * scale,
        10 * scale,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _monthOpen = !_monthOpen),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_month.year}年${_month.month}月',
                          style: TextStyle(
                            fontSize: 20 * scale,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: 7 * scale),
                        Icon(
                          _monthOpen
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          size: 17 * scale,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 4 * scale),
                        Text(
                          _monthOpen ? '关闭日历' : '打开日历',
                          style: TextStyle(
                            fontSize: 12 * scale,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_sameDay(_selected, DateTime.now()))
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 9 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE9FF),
                    borderRadius: BorderRadius.circular(18 * scale),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7 * scale,
                        height: 7 * scale,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4 * scale),
                      Text(
                        '今天',
                        style: TextStyle(
                          fontSize: 12 * scale,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                )
              else
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: Size(0, 32 * scale),
                    padding: EdgeInsets.symmetric(horizontal: 12 * scale),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: const Color(0xFF0B50C8),
                    elevation: 2 * scale,
                    shadowColor: const Color(0x330B50C8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22 * scale),
                    ),
                  ),
                  onPressed: () => setState(() {
                    _selected = DateTime.now();
                    _monthOffset = 0;
                    _monthOpen = false;
                  }),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7 * scale,
                        height: 7 * scale,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Text(
                        '回到今天',
                        style: TextStyle(
                          fontSize: 13 * scale,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 12 * scale),
          if (_monthOpen) ...[
            _monthGrid(monthDays, scale),
            SizedBox(height: 14 * scale),
            Divider(height: 1, thickness: 1, color: const Color(0xFFF0F1F5)),
            SizedBox(height: 10 * scale),
            _calendarLegend(scale),
          ] else ...[
            _weekStrip(weekDays, scale),
            SizedBox(height: 12 * scale),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F5)),
            SizedBox(height: 9 * scale),
            _calendarLegend(scale),
          ],
        ],
      ),
    );
  }

  Widget _calendarLegend(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('紧急任务', const Color(0xFFC51F27), scale),
        SizedBox(width: 12 * scale),
        _legendItem('会议协同', const Color(0xFF2F6FED), scale),
        SizedBox(width: 12 * scale),
        _legendItem('智序专注', const Color(0xFF7429D9), scale),
      ],
    );
  }

  Widget _legendItem(String text, Color color, double scale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8 * scale,
          height: 8 * scale,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6 * scale),
        Text(
          text,
          style: TextStyle(
            fontSize: 10 * scale,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _weekStrip(List<DateTime> days, double scale) {
    return Row(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final selected = _sameDay(day, _selected);
        final today = _sameDay(day, DateTime.now());
        final hovered = _hoveredDay != null && _sameDay(day, _hoveredDay!);
        return Expanded(
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredDay = day),
            onExit: (_) => setState(() => _hoveredDay = null),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _selected = day),
              child: SizedBox(
                height: 112 * scale,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (selected || hovered)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 52 * scale,
                          height: 106 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(18 * scale),
                            border: Border.all(
                              color: const Color(0xFFC1D5FF),
                              width: 1.2 * scale,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 9 * scale,
                      child: Text(
                        _weekdays[index],
                        style: TextStyle(
                          fontSize: 12 * scale,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 39 * scale,
                      child: selected || today
                          ? Container(
                              width: 42 * scale,
                              height: 42 * scale,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFDCE6FF),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(
                                        color: const Color(0xFFCFDFFF),
                                        width: 3 * scale,
                                      )
                                    : null,
                              ),
                              child: Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 16 * scale,
                                  fontWeight: FontWeight.w800,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 42 * scale,
                              height: 42 * scale,
                              child: Align(
                                alignment: Alignment.center,
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 14 * scale,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 84 * scale,
                      child: _dayDots(index, selected, scale),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _dayDots(int index, bool selected, double scale) {
    final day = _selected.subtract(
      Duration(days: (_selected.weekday % 7) - index),
    );
    final colors = _eventColors(day);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < colors.length; i++) ...[
          Container(
            width: 7 * scale,
            height: 7 * scale,
            decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
          ),
          if (i < colors.length - 1) SizedBox(width: 3 * scale),
        ],
      ],
    );
  }

  Widget _monthGrid(List<DateTime> days, double scale) {
    return Column(
      children: [
        Row(
          children: _weekdays
              .map(
                (day) => Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 5 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 34 * scale,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final selected = _sameDay(day, _selected);
            final inMonth = day.month == _month.month;
            return InkWell(
              onTap: () => setState(() {
                _selected = day;
                _monthOpen = false;
              }),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28 * scale,
                    height: 28 * scale,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(7 * scale),
                    ),
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 12 * scale,
                        color: selected
                            ? Colors.white
                            : inMonth
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_hasCalendarEvent(day)) ...[
                    SizedBox(height: 0 * scale),
                    _monthEventDots(day, scale),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _monthEventDots(DateTime day, double scale) {
    final colors = _eventColors(day);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < colors.length; i++)
          Container(
            width: 3 * scale,
            height: 3 * scale,
            decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle),
          ),
      ],
    );
  }

  Widget _daySummary(double scale) {
    return _card(
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        16 * scale,
        14 * scale,
        14 * scale,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selected.month}月${_selected.day}日 ${_weekday(_selected)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18 * scale,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9 * scale),
                Text(
                  '全天负荷适中，AI已为您优化日程节奏',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12 * scale,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_completedTasks.length} / 5',
                  style: TextStyle(
                    fontSize: 25 * scale,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 5 * scale),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      _tag(
                        '已完成 ${_completedTasks.length}',
                        const Color(0xFFE6F0FF),
                        AppColors.primary,
                      ),
                      SizedBox(width: 4 * scale),
                      _tag(
                        '进行中 ${_focusRunning ? '1' : '1'}',
                        const Color(0xFFF0E7FF),
                        const Color(0xFF712AE2),
                      ),
                      SizedBox(width: 4 * scale),
                      _tag(
                        '待办 ${5 - _completedTasks.length - 1}',
                        const Color(0xFFFFE9E9),
                        const Color(0xFFE54646),
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

  Widget _timeline(double scale) {
    return Stack(
      children: [
        Positioned(
          left: 36 * scale,
          top: 0,
          bottom: 0,
          child: Container(width: 1 * scale, color: const Color(0xFFE1E5EF)),
        ),
        Column(
          children: [
            _timelineItem(
              scale,
              '09:00',
              '10:00',
              '每周站会与平台消息同步',
              '钉钉群组会议 · 研发一部',
              '已完成',
              const Color(0xFFB7BBC8),
              taskIndex: 0,
            ),
            _timelineItem(
              scale,
              '10:30',
              '12:00',
              '计算机系统结构线上复习',
              '学习通平台 · 第7讲 流水线优化',
              '已完成',
              const Color(0xFFB7BBC8),
              taskIndex: 1,
            ),
            _timelineItem(
              scale,
              '14:00',
              '15:30',
              '编写智能助手交互原型',
              'Figma · 智序 iOS/Android 组件定义',
              '进行中',
              AppColors.primary,
              active: true,
              taskIndex: 2,
            ),
            _timelineItem(
              scale,
              '15:30',
              '16:30',
              '深入复习与作业提交',
              '已开启免打扰模式与课件智能摘要关联',
              '待办事项',
              AppColors.primary,
              taskIndex: 3,
            ),
            _timelineItem(
              scale,
              '19:30',
              '20:30',
              'Q4 需求评审',
              '腾讯会议 · 会议号 849-204-118',
              '待办事项',
              AppColors.primary,
              action: '进入',
              taskIndex: 4,
            ),
          ],
        ),
      ],
    );
  }

  Widget _timelineItem(
    double scale,
    String time,
    String endTime,
    String title,
    String subtitle,
    String status,
    Color color, {
    bool active = false,
    String? action,
    int? taskIndex,
  }) {
    final completed = taskIndex != null && _completedTasks.contains(taskIndex);
    final shownStatus = taskIndex != null && taskIndex != 2
        ? (completed ? '已完成' : '待办事项')
        : status;
    return Padding(
      padding: EdgeInsets.only(bottom: 9 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 68 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 7 * scale),
                Container(
                  width: active ? 16 * scale : 12 * scale,
                  height: active ? 16 * scale : 12 * scale,
                  padding: EdgeInsets.all(3 * scale),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFDCE8FF) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: active
                          ? AppColors.primary
                          : const Color(0xFFB8BECE),
                      width: active ? 2 * scale : 1.5 * scale,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : const Color(0xFF8B91A2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                10 * scale,
                10 * scale,
                10 * scale,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: active ? AppColors.primary : const Color(0xFFE8E9F0),
                  width: active ? 1.6 * scale : 1 * scale,
                ),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x1C5B5FEF),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              foregroundDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border(
                  left: BorderSide(
                    color: active ? AppColors.primary : const Color(0xFF7A8091),
                    width: 4 * scale,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _tag(
                              shownStatus,
                              active || shownStatus == '待办事项'
                                  ? AppColors.primary
                                  : const Color(0xFFE4EEFF),
                              active || shownStatus == '待办事项'
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              scale: scale,
                            ),
                            SizedBox(width: 7 * scale),
                            Expanded(
                              child: Text(
                                '$time - $endTime',
                                style: TextStyle(
                                  fontSize: 9 * scale,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (action != null) ...[
                              InkWell(
                                onTap: () => _message('会议接入中，请稍候'),
                                borderRadius: BorderRadius.circular(4),
                                child: _tag(
                                  action,
                                  const Color(0xFFE4EEFF),
                                  AppColors.primary,
                                  scale: scale,
                                ),
                              ),
                              SizedBox(width: 5 * scale),
                            ],
                            if (active)
                              InkWell(
                                onTap: () {
                                  setState(
                                    () => _focusRunning = !_focusRunning,
                                  );
                                  _message(_focusRunning ? '专注已开始' : '专注已暂停');
                                },
                                child: Container(
                                  width: 26 * scale,
                                  height: 26 * scale,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _focusRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 17 * scale,
                                    color: Colors.white,
                                  ),
                                ),
                              )
                            else
                              AnimatedScale(
                                scale: completed ? 1.06 : 1,
                                duration: const Duration(milliseconds: 140),
                                curve: Curves.easeOutBack,
                                child: InkWell(
                                  onTap: taskIndex == null
                                      ? null
                                      : () => setState(() {
                                          if (_completedTasks.contains(
                                            taskIndex,
                                          )) {
                                            _completedTasks.remove(taskIndex);
                                          } else {
                                            _completedTasks.add(taskIndex);
                                          }
                                        }),
                                  child: Container(
                                    width: 24 * scale,
                                    height: 24 * scale,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5EEFF),
                                      borderRadius: BorderRadius.circular(
                                        6 * scale,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      size: 15 * scale,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            decoration: shownStatus == '已完成'
                                ? TextDecoration.lineThrough
                                : null,
                            color: shownStatus == '已完成'
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 3 * scale),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 13 * scale,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 5 * scale),
                            Expanded(
                              child: Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11 * scale,
                                  height: 1.35,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickInput(double scale) {
    return _card(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * scale,
        vertical: 9 * scale,
      ),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 18 * scale,
            color: const Color(0xFF712AE2),
          ),
          SizedBox(width: 9 * scale),
          Expanded(
            child: TextField(
              controller: _quickInputController,
              decoration: InputDecoration(
                hintText: '输入“明晚8点和导师讨论论文”…',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintStyle: TextStyle(
                  fontSize: 13 * scale,
                  color: AppColors.textSecondary,
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _message('已收到日程：$value');
                  _quickInputController.clear();
                }
              },
            ),
          ),
          Container(
            width: 28 * scale,
            height: 28 * scale,
            decoration: const BoxDecoration(
              color: Color(0xFFE6EEFF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_none_rounded,
              size: 16 * scale,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiButton(double scale) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: _showAiSuggestion,
        icon: const Icon(Icons.auto_awesome, size: 14),
        label: Text(
          'AI 智能日程',
          style: TextStyle(fontSize: 13 * scale, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shadowColor: const Color(0x665B5FEF),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: 16 * scale,
            vertical: 10 * scale,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22 * scale),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E9F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tag(
    String text,
    Color background,
    Color foreground, {
    double scale = 1,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10 * scale,
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<DateTime> _monthDays() {
    final first = DateTime(_month.year, _month.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    final count = DateUtils.getDaysInMonth(_month.year, _month.month);
    final weeks = (count + first.weekday % 7 + 6) ~/ 7;
    return List.generate(
      weeks * 7,
      (index) => start.add(Duration(days: index)),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  List<Color> _eventColors(DateTime day) {
    if (day.day % 9 == 0) return [const Color(0xFFC51F27)];
    if (day.day % 4 == 0) return [const Color(0xFF2F6FED)];
    if (day.day % 6 == 0) return [const Color(0xFF7429D9)];
    return const [];
  }

  bool _hasCalendarEvent(DateTime day) {
    if (day.month != _month.month) return false;
    return _eventColors(day).isNotEmpty;
  }

  String _weekday(DateTime date) =>
      ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][date.weekday % 7];

  void _showAiSuggestion() => _message('已为你整理本周空闲时段与排程建议');

  void _showFilters() => showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '日历筛选',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final source in ['全部日历源', '学习通任务', '企业微信', '钉钉日程', '个人安排'])
              CheckboxListTile(
                value: true,
                onChanged: (_) {},
                title: Text(source, style: const TextStyle(fontSize: 14)),
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
              ),
          ],
        ),
      ),
    ),
  );

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _AiPill extends StatelessWidget {
  const _AiPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E8FF),
        borderRadius: BorderRadius.circular(12 * scale),
      ),
      child: Text(
        'AI',
        style: TextStyle(
          fontSize: 11 * scale,
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
