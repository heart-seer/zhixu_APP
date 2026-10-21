import 'dart:async';

import 'package:dio/dio.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import 'domain_models.dart';
import 'local_repository.dart';

/// 通过后端 HTTP 接口读写数据。界面保持同步读取缓存列表，写操作乐观更新后与服务器对账。
class RemoteRepository extends AppRepository {
  RemoteRepository({required Dio dio, required SecureStorage storage})
      : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final SecureStorage _storage;

  final List<Task> _tasks = [];
  final List<CalendarEvent> _events = [];
  final List<Message> _messages = [];

  bool _ready = false;
  String _timezone = 'Asia/Shanghai';
  int _nextId = 0;

  static const int _pageSize = 30;

  DateTime? _taskCursor;
  DateTime? _messageCursor;
  bool _hasMoreTasks = false;
  bool _hasMoreMessages = false;
  bool _loadingMoreTasks = false;
  bool _loadingMoreMessages = false;

  String? lastError;
  int errorVersion = 0;

  bool get ready => _ready;

  @override
  List<Task> get tasks => List.unmodifiable(_tasks);
  @override
  List<CalendarEvent> get events => List.unmodifiable(_events);
  @override
  List<Message> get messages => List.unmodifiable(_messages);

  @override
  Task? taskById(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  @override
  CalendarEvent? eventById(String id) {
    for (final event in _events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Message? messageById(String id) {
    for (final message in _messages) {
      if (message.id == id) return message;
    }
    return null;
  }

  @override
  String newId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${++_nextId}';

  @override
  int get completedTaskCount => _tasks.where((task) => task.completed).length;

  @override
  int get pendingMessageCount =>
      _messages.where((message) => message.pending).length;

  @override
  bool get hasMoreTasks => _hasMoreTasks;
  @override
  bool get hasMoreMessages => _hasMoreMessages;

  @override
  List<CalendarEvent> eventsOn(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day + 1);
    return _events
        .where((event) => event.start.isBefore(end) && event.end.isAfter(start))
        .toList()
      ..sort((a, b) => a.start.compareTo(b.start));
  }

  /// 首次进入时若已有登录令牌则拉取数据，否则保持空列表等待登录。
  Future<void> bootstrap() async {
    final token = await _storage.readToken();
    if (token == null || token.trim().isEmpty) {
      _ready = true;
      notifyListeners();
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    try {
      await _loadPreferences();
      await Future.wait([_loadTasks(), _loadEvents()]);
      await _loadMessages();
    } catch (error) {
      _fail(error);
    } finally {
      _ready = true;
      notifyListeners();
    }
  }

  @override
  Future<void> loadMoreTasks() async {
    final cursor = _taskCursor;
    if (cursor == null || _loadingMoreTasks || !_hasMoreTasks) return;
    _loadingMoreTasks = true;
    notifyListeners();
    try {
      final rows = _objects(await _dio.get(
        ApiEndpoints.tasks,
        queryParameters: {
          'before': cursor.toUtc().toIso8601String(),
          'limit': _pageSize,
        },
      ));
      final known = _tasks.map((task) => task.id).toSet();
      for (final row in rows) {
        final task = _mapTask(row);
        if (known.add(task.id)) _tasks.add(task);
      }
      _taskCursor = rows.isEmpty ? null : _time(rows.last['createdAt']);
      _hasMoreTasks = rows.length == _pageSize;
      _linkEvents();
    } catch (error) {
      _fail(error);
    } finally {
      _loadingMoreTasks = false;
      notifyListeners();
    }
  }

  @override
  Future<void> loadMoreMessages() async {
    final cursor = _messageCursor;
    if (cursor == null || _loadingMoreMessages || !_hasMoreMessages) return;
    _loadingMoreMessages = true;
    notifyListeners();
    try {
      final rows = _objects(await _dio.get(
        ApiEndpoints.messages,
        queryParameters: {
          'before': cursor.toUtc().toIso8601String(),
          'limit': _pageSize,
        },
      ));
      final known = _messages.map((message) => message.id).toSet();
      for (final row in rows) {
        final message = _mapMessage(row);
        if (known.add(message.id)) _messages.add(message);
      }
      _messageCursor = rows.isEmpty ? null : _time(rows.last['receivedAt']);
      _hasMoreMessages = rows.length == _pageSize;
    } catch (error) {
      _fail(error);
    } finally {
      _loadingMoreMessages = false;
      notifyListeners();
    }
  }

  // ---------- 任务 ----------

  @override
  void addTask(Task task) {
    if (taskById(task.id) != null) {
      throw ArgumentError.value(task.id, 'task.id', 'Duplicate ID');
    }
    _tasks.insert(0, task);
    notifyListeners();
    _run(() async {
      await _dio.post(ApiEndpoints.tasks, data: {
        'title': task.title,
        'description': _nullIfEmpty(task.description),
        'categoryCode': task.group,
        'priority': task.priority.name,
        'estimateSeconds': task.estimate?.inSeconds,
        'dueAt': task.dueAt?.toUtc().toIso8601String(),
        'steps': task.steps
            .map((step) => {'title': step.title, 'completed': step.completed})
            .toList(),
      });
      await _loadTasks();
      notifyListeners();
    });
  }

  @override
  void toggleTask(String taskId) {
    final task = taskById(taskId);
    if (task == null) return;
    final target = !task.completed;
    task.completed = target;
    for (final step in task.steps) {
      step.completed = target;
    }
    final event = task.scheduledEventId == null
        ? null
        : eventById(task.scheduledEventId!);
    if (event != null) event.completed = target;
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(
        ApiEndpoints.taskCompletion(task.id),
        data: {'completed': target, 'version': task.version},
      ));
      _replaceTask(_mapTask(row));
      await _loadEvents();
      notifyListeners();
    });
  }

  @override
  void setStepCompleted(String taskId, String stepId, bool completed) {
    final task = taskById(taskId);
    if (task == null) return;
    for (final step in task.steps) {
      if (step.id == stepId) step.completed = completed;
    }
    task.completed = task.steps.every((step) => step.completed);
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(
        ApiEndpoints.stepCompletion(task.id, stepId),
        data: {'completed': completed},
      ));
      _replaceTask(_mapTask(row));
      await _loadEvents();
      notifyListeners();
    });
  }

  @override
  void addStep(String taskId, String title) {
    final task = taskById(taskId);
    if (task == null) return;
    task.steps.add(TaskStep(id: newId('step'), title: title));
    task.completed = false;
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(
        ApiEndpoints.taskSteps(task.id),
        data: {'title': title},
      ));
      _replaceTask(_mapTask(row));
      notifyListeners();
    });
  }

  @override
  void delayTask(String taskId, Duration delay) {
    final task = taskById(taskId);
    if (task == null) return;
    task.dueAt = (task.dueAt ?? DateTime.now()).add(delay);
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.put(
        ApiEndpoints.task(task.id),
        data: {
          'dueAt': task.dueAt?.toUtc().toIso8601String(),
          'version': task.version,
        },
      ));
      _replaceTask(_mapTask(row));
      notifyListeners();
    });
  }

  // ---------- 日程 ----------

  @override
  void addEvent(CalendarEvent event) {
    if (eventById(event.id) != null) {
      throw ArgumentError.value(event.id, 'event.id', 'Duplicate ID');
    }
    if (!event.end.isAfter(event.start)) {
      throw ArgumentError.value(event.end, 'event.end', 'Must be after start');
    }
    _events.add(event);
    final task = event.taskId == null ? null : taskById(event.taskId!);
    if (task != null) task.scheduledEventId = event.id;
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(ApiEndpoints.events, data: {
        'title': event.title,
        'description': _nullIfEmpty(event.subtitle),
        'startsAt': event.start.toUtc().toIso8601String(),
        'endsAt': event.end.toUtc().toIso8601String(),
        'timezoneName': _timezone,
        'taskId': event.taskId == null ? null : int.tryParse(event.taskId!),
        'reminderLeadSeconds': event.reminder ? 900 : null,
      }));
      final fresh = _mapEvent(row);
      final index = _events.indexWhere((item) => item.id == event.id);
      if (index >= 0) _events[index] = fresh;
      await _loadTasks();
      await _loadEvents();
      notifyListeners();
    });
  }

  @override
  void toggleEvent(String eventId) {
    final event = eventById(eventId);
    if (event == null) return;
    if (event.taskId != null) {
      toggleTask(event.taskId!);
      return;
    }
    event.completed = !event.completed;
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(
        ApiEndpoints.eventCompletion(event.id),
        data: {'completed': event.completed, 'version': event.version},
      ));
      final fresh = _mapEvent(row);
      final index = _events.indexWhere((item) => item.id == fresh.id);
      if (index >= 0) _events[index] = fresh;
      notifyListeners();
    });
  }

  @override
  CalendarEvent scheduleTask({
    required String taskId,
    required DateTime start,
    required Duration duration,
    bool reminder = false,
  }) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration');
    }
    final task = taskById(taskId);
    if (task == null) throw ArgumentError.value(taskId, 'taskId');
    if (task.scheduledEventId != null) {
      return eventById(task.scheduledEventId!)!;
    }
    final event = CalendarEvent(
      id: newId('event'),
      title: task.title,
      subtitle: task.platform,
      start: start,
      end: start.add(duration),
      taskId: task.id,
      reminder: reminder,
      completed: task.completed,
    );
    _events.add(event);
    task.scheduledEventId = event.id;
    notifyListeners();
    _run(() async {
      final row = _object(await _dio.post(
        ApiEndpoints.timeBlocks(task.id),
        data: {
          'startsAt': start.toUtc().toIso8601String(),
          'endsAt': start.add(duration).toUtc().toIso8601String(),
          'timezoneName': _timezone,
          'reminderLeadSeconds': reminder ? 900 : null,
        },
      ));
      final fresh = _mapEvent(row);
      final index = _events.indexWhere((item) => item.id == event.id);
      if (index >= 0) _events[index] = fresh;
      await _loadTasks();
      await _loadEvents();
      notifyListeners();
    });
    return event;
  }

  // ---------- 消息 ----------

  @override
  Task confirmMessageExtraction(String messageId) {
    final message = messageById(messageId);
    if (message == null) throw ArgumentError.value(messageId, 'messageId');
    if (message.kind != MessageKind.task) {
      throw StateError('Only task messages can be extracted');
    }
    if (message.linkedTaskId != null) {
      final linked = taskById(message.linkedTaskId!);
      if (linked != null) return linked;
    }
    final optimistic = Task(
      id: newId('task'),
      title: message.title,
      platform: message.source,
      group: '本周待办列表',
      priority: TaskPriority.p1,
      estimate: const Duration(hours: 1),
      description: message.preview,
      dueAt: message.taskDueAt,
    );
    _tasks.insert(0, optimistic);
    message.status = MessageStatus.processed;
    message.linkedTaskId = optimistic.id;
    notifyListeners();
    _run(() async {
      final draft = _object(await _dio.post(ApiEndpoints.messageDraft(messageId)));
      final draftId = draft['id']?.toString();
      if (draftId == null) throw const FormatException('提取草稿缺少标识');
      final result = _object(await _dio.post(
        ApiEndpoints.confirmDraft(draftId),
        data: {'timezone': _timezone},
      ));
      final taskJson = result['task'];
      if (taskJson is Map<String, dynamic>) {
        final fresh = _mapTask(taskJson);
        final index = _tasks.indexWhere(
          (item) => identical(item, optimistic) || item.id == optimistic.id,
        );
        if (index >= 0) {
          _tasks[index] = fresh;
        } else {
          _tasks.insert(0, fresh);
        }
        message.linkedTaskId = fresh.id;
      }
      await _loadMessages();
      notifyListeners();
    });
    return optimistic;
  }

  @override
  void confirmAllMessages() {
    final pending = _messages
        .where((item) => item.pending && item.kind == MessageKind.task)
        .toList();
    for (final message in pending) {
      confirmMessageExtraction(message.id);
    }
  }

  @override
  void markMessageRead(String messageId) {
    final message = messageById(messageId);
    if (message == null) return;
    if (message.read) return;
    message.read = true;
    notifyListeners();
    _run(() async {
      await _dio.post(ApiEndpoints.messageRead(message.id));
    });
  }

  @override
  void addMessage(Message message) {
    if (messageById(message.id) != null) {
      throw ArgumentError.value(message.id, 'message.id', 'Duplicate ID');
    }
    _messages.insert(0, message);
    notifyListeners();
    _run(() async {
      await _dio.post(ApiEndpoints.importMessage, data: {
        'platform': _platformCode(message.source),
        'senderName': message.sender,
        'title': message.title,
        'preview': message.preview,
        'body': _nullIfEmpty(message.detail),
        'kind': message.kind.name,
        'receivedAt': message.receivedAt.toUtc().toIso8601String(),
      });
      await _loadMessages();
      notifyListeners();
    });
  }

  // ---------- 同步 ----------

  Future<void> _loadPreferences() async {
    try {
      final row = _object(await _dio.get(ApiEndpoints.preferences));
      final timezone = row['timezoneName']?.toString();
      if (timezone != null && timezone.isNotEmpty) _timezone = timezone;
    } catch (_) {
      // 偏好读取失败不阻塞主流程，沿用默认时区。
    }
  }

  Future<void> _loadTasks() async {
    final rows = _objects(await _dio.get(
      ApiEndpoints.tasks,
      queryParameters: {'limit': _pageSize},
    ));
    _tasks
      ..clear()
      ..addAll(rows.map(_mapTask));
    _taskCursor = rows.isEmpty ? null : _time(rows.last['createdAt']);
    _hasMoreTasks = rows.length == _pageSize;
    _linkEvents();
  }

  Future<void> _loadEvents() async {
    final now = DateTime.now();
    final rows = _objects(await _dio.get(
      ApiEndpoints.events,
      queryParameters: {
        'start': now.subtract(const Duration(days: 30)).toUtc().toIso8601String(),
        'end': now.add(const Duration(days: 120)).toUtc().toIso8601String(),
        'limit': 200,
      },
    ));
    _events
      ..clear()
      ..addAll(rows.map(_mapEvent));
    _linkEvents();
  }

  Future<void> _loadMessages() async {
    final rows = _objects(await _dio.get(
      ApiEndpoints.messages,
      queryParameters: {'limit': _pageSize},
    ));
    _messages
      ..clear()
      ..addAll(rows.map(_mapMessage));
    _messageCursor = rows.isEmpty ? null : _time(rows.last['receivedAt']);
    _hasMoreMessages = rows.length == _pageSize;
  }

  void _linkEvents() {
    for (final task in _tasks) {
      task.scheduledEventId = null;
    }
    for (final event in _events) {
      if (event.taskId == null) continue;
      final task = taskById(event.taskId!);
      if (task != null) {
        task.scheduledEventId = event.id;
        event.completed = task.completed;
      }
    }
  }

  void _replaceTask(Task fresh) {
    final index = _tasks.indexWhere((item) => item.id == fresh.id);
    if (index >= 0) {
      _tasks[index] = fresh;
    } else {
      _tasks.insert(0, fresh);
    }
    _linkEvents();
  }

  /// 写操作失败时回读服务器数据，撤销界面上的乐观改动。
  void _run(Future<void> Function() action) {
    unawaited(() async {
      try {
        await action();
      } catch (error) {
        _fail(error);
        try {
          await refresh();
        } catch (_) {
          // 网络不可用时保留当前缓存。
        }
      }
    }());
  }

  void _fail(Object error) {
    lastError = error is ApiException ? error.message : '网络异常，请稍后重试';
    errorVersion++;
    notifyListeners();
  }

  // ---------- 映射 ----------

  static Map<String, dynamic> _object(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
    }
    throw const FormatException('接口响应格式不正确');
  }

  static List<Map<String, dynamic>> _objects(Response<dynamic> response) {
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Task _mapTask(Map<String, dynamic> json) {
    final estimateSeconds = (json['estimateSeconds'] as num?)?.toInt();
    final task = Task(
      id: json['id']?.toString() ?? newId('task'),
      title: json['title']?.toString() ?? '',
      platform: '个人自主',
      group: _nullIfEmpty(json['categoryCode']?.toString()) ?? '本周待办列表',
      priority: _priority(json['priority']?.toString()),
      estimate:
          estimateSeconds == null ? null : Duration(seconds: estimateSeconds),
      description: json['description']?.toString() ?? '',
      completed: _isCompleted(json),
      dueAt: _time(json['dueAt']),
      sourceMessageId: json['sourceMessageId']?.toString(),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
    final steps = json['steps'];
    if (steps is List) {
      task.steps
        ..clear()
        ..addAll(steps.whereType<Map<String, dynamic>>().map(
          (step) => TaskStep(
            id: step['id']?.toString() ?? '',
            title: step['title']?.toString() ?? '',
            completed: step['completedAt'] != null,
          ),
        ));
    }
    return task;
  }

  CalendarEvent _mapEvent(Map<String, dynamic> json) {
    final start = _time(json['startsAt']) ?? DateTime.now();
    final end = _time(json['endsAt']) ?? start.add(const Duration(hours: 1));
    final reminder = (json['reminderLeadSeconds'] as num?)?.toInt() ?? 0;
    return CalendarEvent(
      id: json['id']?.toString() ?? newId('event'),
      title: json['title']?.toString() ?? '',
      start: start,
      end: end,
      subtitle: json['description']?.toString() ?? '',
      taskId: json['taskId']?.toString(),
      reminder: reminder > 0,
      completed: _isCompleted(json),
      version: (json['version'] as num?)?.toInt() ?? 0,
    );
  }

  Message _mapMessage(Map<String, dynamic> json) {
    final message = Message(
      id: json['id']?.toString() ?? newId('message'),
      source: _platformName(json['platformCode']?.toString()),
      sender: json['senderName']?.toString() ?? '',
      receivedAt: _time(json['receivedAt']) ?? DateTime.now(),
      title: json['title']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      kind: _kind(json['kind']?.toString()),
      detail: _nullIfEmpty(json['body']?.toString()),
      status: json['status'] == 'pending'
          ? MessageStatus.pending
          : MessageStatus.processed,
    );
    message.read = json['readAt'] != null;
    message.linkedTaskId = json['linkedTaskId']?.toString();
    message.linkedEventId = json['linkedEventId']?.toString();
    return message;
  }

  static bool _isCompleted(Map<String, dynamic> json) =>
      json['completedAt'] != null || json['status'] == 'completed';

  static DateTime? _time(Object? value) {
    if (value == null) return null;
    final text = value.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static TaskPriority _priority(String? value) => TaskPriority.values
      .firstWhere((item) => item.name == value, orElse: () => TaskPriority.normal);

  static MessageKind _kind(String? value) => MessageKind.values
      .firstWhere((item) => item.name == value, orElse: () => MessageKind.attachment);

  static String? _nullIfEmpty(String? value) =>
      value == null || value.trim().isEmpty ? null : value;

  static String _platformName(String? code) {
    switch (code) {
      case 'dingtalk':
        return '钉钉';
      case 'wecom':
        return '企业微信';
      case 'feishu':
        return '飞书';
      case 'chaoxing':
        return '学习通';
      case 'tencent_meeting':
        return '腾讯会议';
      default:
        return '个人自主';
    }
  }

  static String _platformCode(String name) {
    switch (name) {
      case '钉钉':
        return 'dingtalk';
      case '企业微信':
        return 'wecom';
      case '飞书':
        return 'feishu';
      case '学习通':
        return 'chaoxing';
      case '腾讯会议':
        return 'tencent_meeting';
      default:
        return 'personal';
    }
  }
}
