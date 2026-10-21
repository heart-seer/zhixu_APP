import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/domain_models.dart';
import '../shared/local_repository.dart';
import '../shared/data_providers.dart';

import '../../app/theme/app_colors.dart';
import '../shared/app_card.dart';
import '../shared/app_presentation.dart';
import '../shared/main_bottom_nav.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key, this.initialDate});
  final DateTime? initialDate;

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  static const _weekdays = ['日', '一', '二', '三', '四', '五', '六'];

  late DateTime _selected = widget.initialDate ?? DateTime.now();
  int _monthOffset = 0;
  bool _monthOpen = false;
  DateTime? _hoveredDay;
  bool _focusRunning = false;
  bool _monthPickerOpen = false;
  int _pickerYear = DateTime.now().year;
  int _pickerMonth = DateTime.now().month;
  AppRepository get _repository => ref.read(localRepositoryProvider);
  List<CalendarEvent> get _dayEvents => _repository.eventsOn(_selected);
  List<CalendarEvent> get _completedTasks =>
      _dayEvents.where((event) => event.completed).toList();
  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
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
    ref.watch(localRepositoryProvider);
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
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.fromLTRB(16, 2, 16, 175 * width / 440),
            children: [
              _calendarCard(monthDays, weekDays, scale),
              const SizedBox(height: 12),
              _daySummary(scale),
              const SizedBox(height: 10),
              _timeline(scale),
              SizedBox(height: 24 * width / 440),
              _quickInput(scale),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 24 * width / 440,
            child: _aiButton(scale),
          ),
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
    scale *= _monthOpen ? 375 / 440 : 375 / 445;
    return _card(
      radius: _monthOpen ? 18 : 16,
      padding: EdgeInsets.fromLTRB(
        16 * scale,
        (_monthOpen ? 10 : 16) * scale,
        16 * scale,
        (_monthOpen ? 14 : 16) * scale,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(6 * scale),
                          onTap: _openMonthPicker,
                          child: Text(
                            '${_month.year}年${_month.month}月',
                            style: TextStyle(
                              fontSize: 24 * scale,
                              fontWeight: FontWeight.w800,
                              color: _monthPickerOpen
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        SizedBox(width: 7 * scale),
                        InkWell(
                          borderRadius: BorderRadius.circular(8 * scale),
                          onTap: _toggleCalendarView,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                                  fontSize: 14 * scale,
                                  fontWeight: _monthOpen
                                      ? FontWeight.w400
                                      : FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
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
                          fontSize: (_monthOpen ? 14 : 12) * scale,
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
                    minimumSize: Size(0, 22 * scale),
                    padding: EdgeInsets.symmetric(horizontal: 7 * scale),
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
                        width: 6 * scale,
                        height: 6 * scale,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 3 * scale),
                      Text(
                        '回到今天',
                        style: TextStyle(
                          fontSize: 12 * scale,
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F1F5)),
            SizedBox(height: 16 * scale),
            _monthGrid(monthDays, scale),
            SizedBox(height: 10 * scale),
            _calendarLegend(scale),
          ] else ...[
            _weekStrip(weekDays, scale),
            SizedBox(height: 10 * scale),
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
          width: (_monthOpen ? 9 : 8) * scale,
          height: (_monthOpen ? 9 : 8) * scale,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 6 * scale),
        Text(
          text,
          style: TextStyle(
            fontSize: (_monthOpen ? 12 : 10) * scale,
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
                height: 100 * scale,
                child: Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (selected || hovered)
                      Positioned(
                        top: 0,
                        child: Container(
                          width: 51 * scale,
                          height: 100 * scale,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(19 * scale),
                            border: Border.all(
                              color: const Color(0xFFC1D5FF),
                              width: 1.2 * scale,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 13 * scale,
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
                      top: 35 * scale,
                      child: selected || today
                          ? Container(
                              width: 42 * scale,
                              height: 42 * scale,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFCFDFFF)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Container(
                                width: 36 * scale,
                                height: 36 * scale,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : const Color(0xFFDCE6FF),
                                  shape: BoxShape.circle,
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
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      top: 80 * scale,
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
                        fontSize: 14 * scale,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: 10 * scale),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: days.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 42 * scale,
          ),
          itemBuilder: (context, index) {
            final day = days[index];
            final selected = _sameDay(day, _selected);
            final today = _sameDay(day, DateTime.now());
            final hovered = _hoveredDay != null && _sameDay(day, _hoveredDay!);
            final inMonth = day.month == _month.month;
            final eventColors = _eventColors(day);
            return MouseRegion(
              onEnter: (_) => setState(() => _hoveredDay = day),
              onExit: (_) => setState(() => _hoveredDay = null),
              child: InkWell(
                onTap: () => setState(() {
                  _selected = day;
                  _monthOpen = false;
                }),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 2 * scale),
                    height: 38 * scale,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : today
                          ? const Color(0xFFE5EEFF)
                          : hovered
                          ? const Color(0xFFDCDFFF)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8 * scale),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 27 * scale,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14 * scale,
                                color: selected
                                    ? Colors.white
                                    : today || hovered
                                    ? AppColors.primary
                                    : inMonth
                                    ? AppColors.textPrimary
                                    : const Color(0xFFD9DCE5),
                                fontWeight: selected || today || hovered
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        if (eventColors.isNotEmpty)
                          _monthEventDots(day, scale, selected: selected),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _monthEventDots(DateTime day, double scale, {bool selected = false}) {
    final colors = _eventColors(day);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < colors.length; i++)
          Container(
            width: 5 * scale,
            height: 5 * scale,
            decoration: BoxDecoration(
              color: selected ? Colors.white : AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  Widget _daySummary(double scale) {
    final now = DateTime.now();
    final inProgress = _dayEvents
        .where(
          (event) =>
              !event.completed &&
              !event.start.isAfter(now) &&
              event.end.isAfter(now),
        )
        .length;
    return _card(
      radius: 20 * scale,
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
                  '${_selected.month}月${_selected.day}日 星期${_weekdays[_selected.weekday % 7]}',
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
                  '全天负荷适中，AI已为您优化\n日程节奏',
                  maxLines: 2,
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
                  '${_completedTasks.length} / ${_dayEvents.length}',
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
                        '进行中 $inProgress',
                        const Color(0xFFF0E7FF),
                        const Color(0xFF712AE2),
                      ),
                      SizedBox(width: 4 * scale),
                      _tag(
                        '待办 ${_dayEvents.length - _completedTasks.length - inProgress}',
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
          left: 23.5 * scale,
          top: 0,
          bottom: 0,
          child: Container(width: 1 * scale, color: const Color(0xFFE1E5EF)),
        ),
        Column(
          children: [
            if (_dayEvents.isEmpty)
              const Padding(padding: EdgeInsets.all(24), child: Text('当日暂无日程')),
            ..._dayEvents.asMap().entries.map(
              (entry) => _timelineItem(
                scale,
                _time(entry.value.start),
                _time(entry.value.end),
                entry.value.title,
                entry.value.subtitle,
                event: entry.value,
                active:
                    !entry.value.start.isAfter(DateTime.now()) &&
                    entry.value.end.isAfter(DateTime.now()),
                isLast: entry.key == _dayEvents.length - 1,
              ),
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
    String subtitle, {
    bool active = false,
    String? action,
    required CalendarEvent event,
    bool isLast = false,
  }) {
    final completed = event.completed;
    final isActive = active && !completed;
    final status = completed
        ? '已完成'
        : isActive
        ? '进行中'
        : '待办事项';
    return _calendarTimelineEntry(
      scale: scale,
      time: time,
      endTime: endTime,
      title: title,
      subtitle: subtitle,
      status: status,
      completed: completed,
      active: isActive,
      focusRunning: _focusRunning,
      isLast: isLast,
      action: action,
      onAction: () => _showContentPanel(
        title,
        '$time - $endTime\n$subtitle\n\n会议服务尚未接入，请在对应会议应用中使用会议号加入。',
      ),
      onFocus: () => setState(() => _focusRunning = !_focusRunning),
      onToggleCompleted: () => _repository.toggleEvent(event.id),
    );
  }

  static Widget _calendarTimelineEntry({
    required double scale,
    required String time,
    required String endTime,
    required String title,
    required String subtitle,
    required String status,
    required bool completed,
    required bool active,
    required bool focusRunning,
    required bool isLast,
    required String? action,
    required VoidCallback onAction,
    required VoidCallback onFocus,
    required VoidCallback? onToggleCompleted,
  }) {
    final taskColor = completed ? const Color(0xFF858998) : AppColors.primary;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 9 * scale),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48 * scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 7 * scale),
                Container(
                  width: 12 * scale,
                  height: 12 * scale,
                  padding: EdgeInsets.all(2.5 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: completed
                          ? const Color(0xFFC8CBDA)
                          : AppColors.primary,
                      width: active ? 3 * scale : 1.7 * scale,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: const Color(0xFFDDE3FF),
                              spreadRadius: 4 * scale,
                            ),
                          ]
                        : null,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: completed
                          ? const Color(0xFF858998)
                          : active
                          ? Colors.white
                          : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(height: 4 * scale),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: active ? AppColors.primary : const Color(0xFF858998),
                    fontFamily: 'monospace',
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
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
                borderRadius: BorderRadius.circular(16 * scale),
                border: Border.all(
                  color: active
                      ? const Color(0xFF326BFF)
                      : const Color(0xFFEEEFF5),
                  width: active ? 2 * scale : 1 * scale,
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
              foregroundDecoration: active
                  ? null
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(16 * scale),
                      gradient: LinearGradient(
                        colors: [
                          taskColor,
                          taskColor,
                          taskColor.withValues(alpha: 0),
                          taskColor.withValues(alpha: 0),
                        ],
                        stops: const [0, 0.012, 0.012, 1],
                      ),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppCardTimeRow(
                          leading: _tag(
                            active ? '● $status' : status,
                            active
                                ? const Color(0xFFE0E2FF)
                                : completed
                                ? const Color(0xFFE4EEFF)
                                : const Color(0xFF2865F3),
                            active
                                ? AppColors.primary
                                : completed
                                ? const Color(0xFF606677)
                                : Colors.white,
                            scale: scale,
                          ),
                          spacing: 7 * scale,
                          text: '$time - $endTime',
                          style: TextStyle(
                            fontSize: 9 * scale,
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          trailing: [
                            if (action != null) ...[
                              InkWell(
                                onTap: onAction,
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
                            if (active) ...[
                              InkWell(
                                onTap: onFocus,
                                child: Container(
                                  width: 26 * scale,
                                  height: 26 * scale,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    focusRunning
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 17 * scale,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 5 * scale),
                            ],
                            AnimatedScale(
                              scale: completed ? 1.06 : 1,
                              duration: const Duration(milliseconds: 140),
                              curve: Curves.easeOutBack,
                              child: InkWell(
                                onTap: onToggleCompleted,
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
                                    color: completed
                                        ? AppColors.primary
                                        : const Color(0xFF858998),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5 * scale),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13 * scale,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: completed
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
      radius: 14 * scale,
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
              style: TextStyle(fontSize: 13 * scale),
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
                  _showContentPanel(
                    '日程输入',
                    '待添加内容：${value.trim()}\n\n日程解析与添加尚未接入，内容未写入日历。',
                  );
                }
              },
            ),
          ),
          InkWell(
            onTap: () =>
                _showContentPanel('语音添加日程', '语音识别与日程添加尚未接入，当前无法录音或写入日程。'),
            borderRadius: BorderRadius.circular(14 * scale),
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _aiButton(double scale) {
    scale *= 375 / 440;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 137 * scale,
        height: 45 * scale,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7825E9), Color(0xFF2463EF)],
          ),
          borderRadius: BorderRadius.circular(24 * scale),
          boxShadow: [
            BoxShadow(
              color: const Color(0x335B5FEF),
              blurRadius: 8 * scale,
              offset: Offset(0, 4 * scale),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24 * scale),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _showAiSuggestion,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12 * scale,
                vertical: 11 * scale,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 19 * scale,
                    color: Colors.white,
                  ),
                  SizedBox(width: 6 * scale),
                  Text(
                    'AI 编排日程',
                    style: TextStyle(
                      fontSize: 12 * scale,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 16,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
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

  static Widget _tag(
    String text,
    Color background,
    Color foreground, {
    double scale = 1,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 2 * scale),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12 * scale),
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
    return _repository
        .eventsOn(day)
        .take(3)
        .map(
          (event) => event.completed
              ? const Color(0xFF858998)
              : const Color(0xFF2F6FED),
        )
        .toList();
  }

  void _toggleCalendarView() => setState(() => _monthOpen = !_monthOpen);

  Future<void> _openMonthPicker() async {
    setState(() {
      _monthPickerOpen = true;
      _pickerYear = _month.year;
      _pickerMonth = _month.month;
    });

    final result = await showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => _YearMonthWheelSheet(
          year: _pickerYear,
          month: _pickerMonth,
          onYearChanged: (year) => setDialogState(() => _pickerYear = year),
          onMonthChanged: (month) => setDialogState(() => _pickerMonth = month),
          onCancel: () => Navigator.pop(dialogContext),
          onConfirm: () =>
              Navigator.pop(dialogContext, DateTime(_pickerYear, _pickerMonth)),
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _monthPickerOpen = false;
      if (result != null) {
        final selectedDay = _selected.day;
        final lastDay = DateUtils.getDaysInMonth(result.year, result.month);
        _selected = DateTime(
          result.year,
          result.month,
          selectedDay > lastDay ? lastDay : selectedDay,
        );
        _monthOffset = 0;
      }
    });
  }

  void _showAiSuggestion() => _showContentPanel(
    'AI 智能日程',
    '当前本地安排：\n14:00 - 15:30 编写智能助手交互原型\n15:30 - 16:30 深入复习与作业提交\n19:30 - 20:30 Q4 需求评审\n\nAI 排程服务尚未接入，以上为页面已有安排，未生成建议或调整日程。',
  );

  void _showFilters() => showAppDialog<void>(
    context: context,
    title: '日历筛选',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
  );

  void _showContentPanel(String title, String content) => showAppDialog<void>(
    context: context,
    title: title,
    child: Text(content, style: const TextStyle(height: 1.5)),
  );
}

class _YearMonthWheelSheet extends StatefulWidget {
  const _YearMonthWheelSheet({
    required this.year,
    required this.month,
    required this.onYearChanged,
    required this.onMonthChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final int year;
  final int month;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<int> onMonthChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_YearMonthWheelSheet> createState() => _YearMonthWheelSheetState();
}

class _YearMonthWheelSheetState extends State<_YearMonthWheelSheet> {
  late final FixedExtentScrollController _yearController;
  late final FixedExtentScrollController _monthController;
  static const _firstYear = 1900;
  static const _lastYear = 2100;

  @override
  void initState() {
    super.initState();
    _yearController = FixedExtentScrollController(
      initialItem: widget.year - _firstYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: widget.month - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260B2C5F),
              blurRadius: 28,
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xFFE8EDF5))),
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: widget.onCancel,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    child: const Text('取消'),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        '选择年月',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onConfirm,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: const Text('完成'),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD7E5FF)),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker.builder(
                          scrollController: _yearController,
                          itemExtent: 48,
                          selectionOverlay: const SizedBox.shrink(),
                          childCount: _lastYear - _firstYear + 1,
                          onSelectedItemChanged: (index) =>
                              widget.onYearChanged(_firstYear + index),
                          itemBuilder: (context, index) => Center(
                            child: Text(
                              '${_firstYear + index}年',
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          scrollController: _monthController,
                          itemExtent: 48,
                          selectionOverlay: const SizedBox.shrink(),
                          onSelectedItemChanged: (index) =>
                              widget.onMonthChanged(index + 1),
                          children: [
                            for (var month = 1; month <= 12; month++)
                              Center(
                                child: Text(
                                  '$month月',
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
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
