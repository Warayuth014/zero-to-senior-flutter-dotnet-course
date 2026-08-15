import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/core/api_client.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/task_store.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';

class FakeTaskRepository implements TaskRepository {
  final tasks = <WmsTask>[
    const WmsTask(
      id: 'TASK-001',
      from: 'A-01',
      to: 'PACK-01',
      status: TaskStatus.waiting,
    ),
  ];
  int completeCalls = 0;
  Completer<TaskCompletion>? pendingCompletion;
  bool throwUnknownOutcome = false;

  @override
  Future<List<WmsTask>> fetchOpen() async => List.of(tasks);

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    completeCalls++;
    if (throwUnknownOutcome) {
      tasks.removeWhere((task) => task.id == id);
      throw const ApiException('timeout', outcomeUnknown: true);
    }
    if (pendingCompletion case final pending?) return pending.future;
    tasks.removeWhere((task) => task.id == id);
    return TaskCompletion(
      id: id,
      alreadyCompleted: false,
      correlationId: 'test-correlation',
    );
  }
}

void main() {
  test('load และ complete อัปเดต single source of truth', () async {
    final store = TaskStore(
      FakeTaskRepository(),
      createCommandId: (_) => 'command-1',
    );
    await store.load();
    expect(store.tasks.single.id, 'TASK-001');

    await store.complete(store.tasks.single);
    expect(store.tasks, isEmpty);
    expect(store.error, isNull);
  });

  test('complete task เดิมระหว่าง request ถูกส่งครั้งเดียว', () async {
    final repository = FakeTaskRepository()
      ..pendingCompletion = Completer<TaskCompletion>();
    final store = TaskStore(repository, createCommandId: (_) => 'command-1');
    await store.load();

    final first = store.complete(store.tasks.single);
    final second = store.complete(store.tasks.single);
    expect(repository.completeCalls, 1);

    repository.pendingCompletion!.complete(
      const TaskCompletion(
        id: 'TASK-001',
        alreadyCompleted: false,
        correlationId: 'corr-1',
      ),
    );
    await Future.wait([first, second]);
    expect(store.tasks, isEmpty);
  });

  test('timeout หลัง mutation จะ reload เพื่อ reconcile', () async {
    final repository = FakeTaskRepository()..throwUnknownOutcome = true;
    final store = TaskStore(repository, createCommandId: (_) => 'command-1');
    await store.load();

    await store.complete(store.tasks.single);

    expect(store.tasks, isEmpty);
    expect(store.error, isNull);
    expect(store.actionMessage, contains('หลังตรวจสอบซ้ำ'));
  });
}
