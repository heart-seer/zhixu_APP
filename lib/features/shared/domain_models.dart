enum TaskPriority { p0, p1, p2, normal }

enum MessageKind { task, calendar, attachment }

enum MessageStatus { pending, processed }

class TaskStep {
  TaskStep({required this.id, required this.title, this.completed = false});

  final String id;
  final String title;
  bool completed;
}

class Task {
  Task({
    required this.id,
    required this.title,
    required this.platform,
    required this.group,
    required this.priority,
    required this.estimate,
    this.description = '',
    this.completed = false,
    this.aiCandidate = false,
    List<String> steps = const [],
    this.dueAt,
    this.sourceMessageId,
    this.version = 0,
  }) : steps = steps
           .asMap()
           .entries
           .map(
             (entry) => TaskStep(
               id: '$id-step-${entry.key + 1}',
               title: entry.value,
               completed: completed,
             ),
           )
           .toList();

  final String id;
  final String? sourceMessageId;
  final String title;
  final String platform;
  final String group;
  final TaskPriority priority;
  final Duration? estimate;
  final String description;
  final bool aiCandidate;
  final List<TaskStep> steps;
  DateTime? dueAt;
  bool completed;
  String? scheduledEventId;
  int version;

  bool get scheduled => scheduledEventId != null;
}

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
    this.subtitle = '',
    this.taskId,
    this.reminder = false,
    this.completed = false,
    this.version = 0,
  });

  final String id;
  final String title;
  final DateTime start;
  final DateTime end;
  final String subtitle;
  final String? taskId;
  final bool reminder;
  bool completed;
  int version;
}

class Message {
  Message({
    required this.id,
    required this.source,
    required this.sender,
    required this.receivedAt,
    required this.title,
    required this.preview,
    required this.kind,
    this.highlight,
    this.detail,
    this.category,
    this.footer,
    this.status = MessageStatus.pending,
    this.linkedTaskId,
    this.linkedEventId,
    this.taskDueAt,
  });

  final String id;
  final String source;
  final String sender;
  final DateTime receivedAt;
  final String title;
  final String preview;
  final MessageKind kind;
  final String? highlight;
  final String? detail;
  final String? category;
  final String? footer;
  MessageStatus status;
  String? linkedTaskId;
  final String? linkedEventId;
  final DateTime? taskDueAt;
  bool read = false;

  bool get pending => status == MessageStatus.pending;
}
