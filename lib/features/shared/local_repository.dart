import 'package:flutter/foundation.dart';

import 'domain_models.dart';

abstract class AppRepository extends ChangeNotifier {
  List<Task> get tasks;
  List<CalendarEvent> get events;
  List<Message> get messages;
  Task? taskById(String id);
  CalendarEvent? eventById(String id);
  Message? messageById(String id);
  String newId(String prefix);
  int get completedTaskCount;
  int get pendingMessageCount;
  List<CalendarEvent> eventsOn(DateTime day);
  void addTask(Task task);
  void toggleTask(String taskId);
  void setStepCompleted(String taskId, String stepId, bool completed);
  void addStep(String taskId, String title);
  void delayTask(String taskId, Duration delay);
  void addEvent(CalendarEvent event);
  void toggleEvent(String eventId);
  CalendarEvent scheduleTask({
    required String taskId,
    required DateTime start,
    required Duration duration,
    bool reminder = false,
  });
  Task confirmMessageExtraction(String messageId);
  void confirmAllMessages();
  void markMessageRead(String messageId);
  void addMessage(Message message);

  bool get hasMoreTasks => false;
  Future<void> loadMoreTasks() async {}
  bool get hasMoreMessages => false;
  Future<void> loadMoreMessages() async {}

  String? get displayName => null;
  String? get occupation => null;
  String? get currentGoal => null;
}

class LocalRepository extends AppRepository {
  LocalRepository.seeded()
    : _tasks = _seedTasks(),
      _events = _seedEvents(),
      _messages = _seedMessages();

  LocalRepository.empty() : _tasks = [], _events = [], _messages = [];

  final List<Task> _tasks;
  final List<CalendarEvent> _events;
  final List<Message> _messages;

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);
  @override
  List<CalendarEvent> get events => List.unmodifiable(_events);
  @override
  List<Message> get messages => List.unmodifiable(_messages);

  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  CalendarEvent? eventById(String id) {
    for (final event in events) {
      if (event.id == id) return event;
    }
    return null;
  }

  Message? messageById(String id) {
    for (final message in messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  int _nextId = 0;

  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${++_nextId}';

  int get completedTaskCount => _tasks.where((task) => task.completed).length;
  int get pendingMessageCount =>
      messages.where((message) => message.pending).length;

  List<CalendarEvent> eventsOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    return events
        .where((event) => event.start.isBefore(end) && event.end.isAfter(start))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  void addTask(Task task) {
    if (taskById(task.id) != null)
      throw ArgumentError.value(task.id, 'task.id', 'Duplicate ID');
    _tasks.insert(0, task);
    notifyListeners();
  }

  void setStepCompleted(String taskId, String stepId, bool completed) {
    final task = taskById(taskId)!;
    task.steps.firstWhere((step) => step.id == stepId).completed = completed;
    task.completed = task.steps.every((step) => step.completed);
    final event = task.scheduledEventId == null
        ? null
        : eventById(task.scheduledEventId!);
    if (event != null) event.completed = task.completed;
    notifyListeners();
  }

  void addStep(String taskId, String title) {
    final task = taskById(taskId)!;
    task.steps.add(TaskStep(id: newId('step'), title: title));
    task.completed = false;
    final event = task.scheduledEventId == null
        ? null
        : eventById(task.scheduledEventId!);
    if (event != null) event.completed = false;
    notifyListeners();
  }

  void delayTask(String taskId, Duration delay) {
    final task = taskById(taskId)!;
    task.dueAt = (task.dueAt ?? DateTime.now()).add(delay);
    notifyListeners();
  }

  void toggleEvent(String eventId) {
    final event = eventById(eventId)!;
    if (event.taskId != null) {
      toggleTask(event.taskId!);
    } else {
      event.completed = !event.completed;
      notifyListeners();
    }
  }

  void addEvent(CalendarEvent event) {
    if (eventById(event.id) != null)
      throw ArgumentError.value(event.id, 'event.id', 'Duplicate ID');
    if (!event.end.isAfter(event.start)) {
      throw ArgumentError.value(event.end, 'event.end', 'Must be after start');
    }
    final task = event.taskId == null ? null : taskById(event.taskId!);
    if (event.taskId != null && task == null) {
      throw ArgumentError.value(event.taskId, 'event.taskId');
    }
    if (task != null) {
      if (task.scheduled) throw StateError('Task already scheduled');
      task.scheduledEventId = event.id;
      event.completed = task.completed;
    }
    _events.add(event);
    notifyListeners();
  }

  void toggleTask(String taskId) {
    final task = taskById(taskId);
    if (task == null) return;
    task.completed = !task.completed;
    for (final step in task.steps) {
      step.completed = task.completed;
    }
    final event = task.scheduledEventId == null
        ? null
        : eventById(task.scheduledEventId!);
    if (event != null) event.completed = task.completed;
    notifyListeners();
  }

  CalendarEvent scheduleTask({
    required String taskId,
    required DateTime start,
    required Duration duration,
    bool reminder = false,
  }) {
    if (duration <= Duration.zero)
      throw ArgumentError.value(duration, 'duration');
    final task = taskById(taskId);
    if (task == null) throw ArgumentError.value(taskId, 'taskId');
    if (task.scheduledEventId != null)
      return eventById(task.scheduledEventId!)!;
    final event = CalendarEvent(
      id: 'event-$taskId',
      title: task.title,
      subtitle: task.platform,
      start: start,
      end: start.add(duration),
      taskId: task.id,
      reminder: reminder,
      completed: task.completed,
    );
    addEvent(event);
    return event;
  }

  Task confirmMessageExtraction(String messageId) {
    final message = messageById(messageId);
    if (message == null) throw ArgumentError.value(messageId, 'messageId');
    if (message.kind != MessageKind.task)
      throw StateError('Only task messages can be extracted');
    if (message.linkedTaskId != null) return taskById(message.linkedTaskId!)!;
    final task = Task(
      sourceMessageId: message.id,
      id: 'task-from-$messageId',
      title: message.title,
      platform: message.source,
      group: '本周待办列表',
      priority: TaskPriority.p1,
      estimate: const Duration(hours: 1),
      description: message.preview,
      dueAt: message.taskDueAt,
    );
    if (taskById(task.id) != null)
      throw StateError('Extraction task ID already exists');
    _tasks.insert(0, task);
    message.linkedTaskId = task.id;
    message.status = MessageStatus.processed;
    notifyListeners();
    return task;
  }

  void confirmAllMessages() {
    for (final message in messages.where(
      (item) => item.pending && item.kind == MessageKind.task,
    )) {
      confirmMessageExtraction(message.id);
    }
  }

  void markMessageRead(String messageId) {
    messageById(messageId)!.read = true;
    notifyListeners();
  }

  void addMessage(Message message) {
    if (messageById(message.id) != null)
      throw ArgumentError.value(message.id, 'message.id', 'Duplicate ID');
    _messages.insert(0, message);
    notifyListeners();
  }
}

DateTime _todayAt(int hour, {int days = 0}) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + days, hour);
}

List<Task> _seedTasks() => [
  Task(
    id: 'task-data-structures-report',
    dueAt: _todayAt(23),
    title: '完成数据结构实验报告',
    platform: '学习通',
    group: '即将截止 / P0 紧急',
    priority: TaskPriority.p0,
    estimate: const Duration(hours: 3),
    steps: [
      '红黑树插入与平衡旋转算法实现代码整理',
      '绘制算法性能对比折线图 (Gnuplot / Excel)',
      '撰写实验结论与空间复杂度差异分析',
      '导出 PDF 格式并提交至学习通系统',
    ],
  ),
  Task(
    id: 'task-q3-weekly-report',
    dueAt: _todayAt(17),
    title: '提交敏捷研发组 Q3 阶段总结周报',
    platform: '企业微信',
    group: '即将截止 / P0 紧急',
    priority: TaskPriority.p0,
    estimate: const Duration(minutes: 45),
  ),
  Task(
    id: 'task-service-topology',
    title: '分布式高并发系统架构拓扑图绘制',
    platform: '个人自主',
    group: '今日进行中',
    priority: TaskPriority.p1,
    estimate: const Duration(minutes: 90),
    description: '已完成网关与鉴权模块，待补全 Redis 缓存集群同步流向。',
  ),
  Task(
    id: 'task-computer-architecture-review',
    title: '计算机体系结构期中重点知识点复习',
    platform: '学习通',
    group: '今日进行中',
    priority: TaskPriority.p1,
    estimate: const Duration(hours: 1),
    aiCandidate: true,
  ),
  Task(
    id: 'task-graduate-presentation',
    title: '研究生组会文献 PPT 预讲',
    platform: '钉钉',
    group: '本周待办列表',
    priority: TaskPriority.normal,
    estimate: const Duration(hours: 2),
  ),
  Task(
    id: 'task-mentor-weekly-cc',
    title: '发送导师周报抄送知悉',
    platform: '企业微信',
    group: '本周待办列表',
    priority: TaskPriority.normal,
    estimate: const Duration(minutes: 30),
    completed: true,
  ),
];

List<CalendarEvent> _seedEvents() {
  final now = DateTime.now();
  return [
    CalendarEvent(
      id: 'event-daily-standup',
      title: '敏捷研发团队每日站会',
      subtitle: '钉钉群组会议 · 研发一部',
      start: DateTime(now.year, now.month, now.day, 10),
      end: DateTime(now.year, now.month, now.day, 10, 30),
      completed: true,
    ),
    CalendarEvent(
      id: 'event-product-review',
      title: '产品迭代对齐会',
      subtitle: '腾讯会议 · 本地示例日程',
      start: DateTime(now.year, now.month, now.day, 16, 30),
      end: DateTime(now.year, now.month, now.day, 17, 30),
      reminder: true,
    ),
  ];
}

List<Message> _seedMessages() {
  final now = DateTime.now();
  return [
    Message(
      id: 'message-calculus-homework',
      taskDueAt: DateTime(
        now.year,
        now.month,
        now.day + (DateTime.friday - now.weekday + 7) % 7,
        22,
      ),
      source: '学习通',
      sender: '高数课代表通知',
      receivedAt: now.subtract(const Duration(minutes: 10)),
      title: '第五章课后习题',
      preview: '各位同学，第五章课后习题请于本周五晚22:00前提交到系统。',
      highlight: '本周五晚22:00前',
      detail: '截止时间: 周五22:00 · 优先级: P1紧急',
      category: '分类: 学业作业',
      footer: '本地示例消息',
      kind: MessageKind.task,
    ),
    Message(
      id: 'message-hardware-requirement',
      taskDueAt: DateTime(now.year, now.month, now.day, 16),
      source: '企业微信',
      sender: '李总监 (产品规划组)',
      receivedAt: now.subtract(const Duration(minutes: 35)),
      title: 'Q4智能硬件需求文档初稿',
      preview: '@全员 请在今天下午16:00前将Q4智能硬件需求文档初稿同步给测试组。',
      highlight: '今天下午16:00前',
      detail: '截止时间: 今日16:00 · 指派人: 李总监',
      category: '涉及交付物: Q4需求文档初稿',
      footer: '本地示例消息',
      kind: MessageKind.task,
    ),
    Message(
      id: 'message-product-meeting',
      source: '腾讯会议',
      sender: '系统通知',
      receivedAt: now,
      title: '产品迭代对齐会',
      preview: '您已成功预约并受邀参会：产品迭代对齐会。',
      detail: '本地日程示例，未接入会议服务。',
      status: MessageStatus.processed,
      kind: MessageKind.calendar,
      linkedEventId: 'event-product-review',
    ),
    Message(
      id: 'message-service-mesh-file',
      source: '钉钉',
      sender: '架构研发项目组',
      receivedAt: now.subtract(const Duration(hours: 2)),
      title: 'Q4-Service-Mesh-Refactor.pdf',
      preview: '架构评审会参考材料已共享至云盘。',
      footer: '本地附件示例，未接入文件服务',
      status: MessageStatus.processed,
      kind: MessageKind.attachment,
    ),
  ];
}
