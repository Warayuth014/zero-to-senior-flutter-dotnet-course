import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';
import 'package:flutter_wms_companion/offline/offline_database.dart';
import 'package:flutter_wms_companion/offline/offline_task_repository.dart';

class OfflineRemoteFake implements TaskRepository {
  final tasks = <WmsTask>[
    const WmsTask(
      id: 'TASK-001',
      from: 'A-01',
      to: 'PACK-01',
      status: TaskStatus.waiting,
    ),
  ];
  bool failReads = false;
  bool failCommands = false;
  final commandIds = <String>[];

  @override
  Future<List<WmsTask>> fetchOpen() async {
    if (failReads) throw Exception('offline');
    return List.of(tasks);
  }

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    commandIds.add(commandId);
    if (failCommands) throw Exception('offline');
    tasks.removeWhere((task) => task.id == id);
    return TaskCompletion(
      id: id,
      alreadyCompleted: false,
      correlationId: 'server-correlation',
    );
  }
}

void main() {
  late OfflineDatabase database;
  late OfflineRemoteFake remote;
  late OfflineTaskRepository repository;

  setUp(() {
    database = OfflineDatabase(NativeDatabase.memory());
    remote = OfflineRemoteFake();
    repository = OfflineTaskRepository(remote: remote, database: database);
  });
  tearDown(() => database.close());

  test('read-through cache คืนข้อมูลเดิมเมื่อ network ล่ม', () async {
    expect((await repository.fetchOpen()).single.id, 'TASK-001');
    remote.failReads = true;
    expect((await repository.fetchOpen()).single.id, 'TASK-001');
  });

  test('enqueue complete ซ่อน task และเขียน outbox ใน transaction', () async {
    await repository.fetchOpen();
    final result = await repository.complete(
      'TASK-001',
      commandId: 'command-001',
    );

    expect(result.correlationId, 'queued:command-001');
    expect(await database.visibleTasks(), isEmpty);
    expect((await database.commandsToSync()).single.commandId, 'command-001');
  });

  test(
    'enqueue task ที่ไม่มีใน cache rollback outbox ทั้ง transaction',
    () async {
      await expectLater(
        repository.complete('TASK-404', commandId: 'command-404'),
        throwsStateError,
      );

      expect(await database.commandsToSync(), isEmpty);
    },
  );

  test('sync replay commandId เดิมและ acknowledge outbox', () async {
    await repository.fetchOpen();
    await repository.complete('TASK-001', commandId: 'command-001');

    expect(await repository.syncPending(), 1);
    expect(remote.commandIds, ['command-001']);
    expect(await database.commandsToSync(), isEmpty);
  });

  test('sync failure เก็บ command พร้อม attempts เพื่อ retry', () async {
    await repository.fetchOpen();
    await repository.complete('TASK-001', commandId: 'command-001');
    remote.failCommands = true;

    expect(await repository.syncPending(), 0);
    final pending = (await database.commandsToSync()).single;
    expect(pending.attempts, 1);
    expect(pending.lastError, contains('offline'));
  });
}
