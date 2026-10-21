import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zhixu_app/features/calendar/calendar_page.dart';
import 'package:zhixu_app/features/home/home_page.dart';
import 'package:zhixu_app/features/messages/messages_page.dart';
import 'package:zhixu_app/features/shared/data_providers.dart';
import 'package:zhixu_app/features/shared/domain_models.dart';
import 'package:zhixu_app/features/shared/local_repository.dart';
import 'package:zhixu_app/features/tasks/tasks_page.dart';

void main() {
  test('Message extraction creates one linked task and notifies consumers', () {
    final repository = LocalRepository.seeded();
    addTearDown(repository.dispose);
    var notifications = 0;
    repository.addListener(() => notifications++);
    final before = repository.tasks.length;
    final task = repository.confirmMessageExtraction(
      'message-calculus-homework',
    );
    final message = repository.messageById('message-calculus-homework')!;

    expect(repository.tasks.length, before + 1);
    expect(task.sourceMessageId, message.id);
    expect(task.dueAt, message.taskDueAt);
    expect(message.linkedTaskId, task.id);
    expect(message.status, MessageStatus.processed);
    expect(notifications, 1);
    expect(repository.confirmMessageExtraction(message.id), same(task));
    expect(repository.tasks.length, before + 1);
    repository.confirmAllMessages();
    repository.confirmAllMessages();
    expect(repository.tasks.length, before + 2);
    expect(repository.pendingMessageCount, 0);
  });

  test('Scheduling links both models and completion stays synchronized', () {
    final repository = LocalRepository.seeded();
    addTearDown(repository.dispose);
    final task = repository.tasks.first;
    final start = DateTime(2026, 10, 21, 23, 30);
    final event = repository.scheduleTask(
      taskId: task.id,
      start: start,
      duration: const Duration(hours: 1),
      reminder: true,
    );
    expect(task.scheduledEventId, event.id);
    expect(event.taskId, task.id);
    expect(event.reminder, isTrue);
    expect(repository.eventsOn(start), contains(event));
    expect(repository.eventsOn(DateTime(2026, 10, 22)), contains(event));
    expect(repository.eventsOn(DateTime(2026, 10, 23)), isNot(contains(event)));
    final count = repository.events.length;
    expect(
      repository.scheduleTask(
        taskId: task.id,
        start: start,
        duration: const Duration(hours: 1),
      ),
      same(event),
    );
    expect(repository.events.length, count);

    repository.toggleEvent(event.id);
    expect(task.completed, isTrue);
    expect(task.steps.every((step) => step.completed), isTrue);
    repository.setStepCompleted(task.id, task.steps.first.id, false);
    expect(task.completed, isFalse);
    expect(event.completed, isFalse);
    repository.toggleTask(task.id);
    repository.addStep(task.id, 'New step');
    expect(task.completed, isFalse);
    expect(event.completed, isFalse);
  });

  test('Repository collections cannot bypass commands and notifications', () {
    final repository = LocalRepository.seeded();
    addTearDown(repository.dispose);
    final taskCount = repository.tasks.length;
    final eventCount = repository.events.length;
    final messageCount = repository.messages.length;

    expect(() => repository.tasks.clear(), throwsUnsupportedError);
    expect(() => repository.events.clear(), throwsUnsupportedError);
    expect(() => repository.messages.clear(), throwsUnsupportedError);
    expect(repository.tasks.length, taskCount);
    expect(repository.events.length, eventCount);
    expect(repository.messages.length, messageCount);
  });

  test('Invalid linked events leave the task and repository unchanged', () {
    final repository = LocalRepository.seeded();
    addTearDown(repository.dispose);
    final task = repository.tasks.first;
    var notifications = 0;
    repository.addListener(() => notifications++);
    final eventCount = repository.events.length;
    final start = DateTime(2026, 10, 21, 12);

    for (final end in [start, start.subtract(const Duration(hours: 1))]) {
      expect(
        () => repository.addEvent(
          CalendarEvent(
            id: 'invalid-event',
            title: task.title,
            start: start,
            end: end,
            taskId: task.id,
          ),
        ),
        throwsArgumentError,
      );
    }
    expect(task.scheduled, isFalse);
    expect(repository.events.length, eventCount);
    expect(notifications, 0);
  });

  test(
    'Extracted message task stays linked through scheduling and completion',
    () {
      final repository = LocalRepository.seeded();
      addTearDown(repository.dispose);
      final task = repository.confirmMessageExtraction(
        'message-calculus-homework',
      );
      final event = repository.scheduleTask(
        taskId: task.id,
        start: DateTime(2026, 10, 21, 12),
        duration: const Duration(hours: 1),
      );
      repository.toggleEvent(event.id);

      final message = repository.messageById(task.sourceMessageId!)!;
      expect(message.linkedTaskId, task.id);
      expect(repository.taskById(message.linkedTaskId!), same(task));
      expect(task.scheduledEventId, event.id);
      expect(task.completed, isTrue);
      expect(event.completed, isTrue);
      expect(repository.confirmMessageExtraction(message.id), same(task));
      expect(message.status, MessageStatus.processed);
      repository.toggleTask(task.id);
      expect(event.completed, isFalse);
    },
  );

  testWidgets('All four pages react to the injected shared repository', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LocalRepository.seeded();
    final container = ProviderContainer(
      overrides: [repositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(container.dispose);
    Future<void> show(Widget page) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: page),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    await show(const MessagesPage());
    await tester.ensureVisible(find.text('AI 转为任务'));
    await tester.tap(find.text('AI 转为任务'));
    await tester.pumpAndSettle();
    final task = repository.taskById('task-from-message-calculus-homework')!;
    expect(find.text('AI 转为任务'), findsNothing);

    await show(const TasksPage());
    final taskScroll = find
        .byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.scrollUntilVisible(
      find.textContaining(task.title, findRichText: true),
      400,
      scrollable: taskScroll,
    );
    expect(find.textContaining(task.title, findRichText: true), findsWidgets);
    repository.addTask(
      Task(
        id: 'live-task',
        title: '共享监听验证',
        platform: '学习通',
        group: '本周待办列表',
        priority: TaskPriority.p0,
        estimate: const Duration(hours: 1),
        dueAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('共享监听验证', findRichText: true),
      -400,
      scrollable: taskScroll,
    );
    expect(find.textContaining('共享监听验证', findRichText: true), findsWidgets);

    await show(const HomePage());
    final now = DateTime.now();
    repository.scheduleTask(
      taskId: 'live-task',
      start: DateTime(now.year, now.month, now.day, 12),
      duration: const Duration(hours: 1),
    );
    await tester.pump();
    expect(find.text('共享监听验证'), findsWidgets);

    await show(CalendarPage(initialDate: now));
    expect(find.text('共享监听验证'), findsWidgets);
    repository.addEvent(
      CalendarEvent(
        id: 'live-event',
        title: '日历监听验证',
        start: DateTime(now.year, now.month, now.day, 14),
        end: DateTime(now.year, now.month, now.day, 15),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('日历监听验证'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Calendar message action opens its linked event date', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = LocalRepository.seeded();
    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(path: '/messages', builder: (_, _) => const MessagesPage()),
        GoRoute(
          path: '/calendar',
          builder: (_, state) => CalendarPage(
            initialDate: DateTime.tryParse(
              state.uri.queryParameters['date'] ?? '',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [repositoryProvider.overrideWith((ref) => repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('查看日程'));
    await tester.tap(find.text('查看日程'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(
      router.routeInformationProvider.value.uri.queryParameters['date'],
      repository.eventById('event-product-review')!.start.toIso8601String(),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
