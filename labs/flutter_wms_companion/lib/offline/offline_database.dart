import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../features/tasks/wms_task.dart';

part 'offline_database.g.dart';

class CachedTasks extends Table {
  TextColumn get id => text()();
  TextColumn get fromLocation => text()();
  TextColumn get toLocation => text()();
  TextColumn get status => text()();
  DateTimeColumn get cachedAt => dateTime()();
  BoolColumn get hiddenByCommand =>
      boolean().withDefault(const Constant(false))();
  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PendingCommands extends Table {
  TextColumn get commandId => text()();
  TextColumn get taskId => text()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  @override
  Set<Column<Object>> get primaryKey => {commandId};
}

@DriftDatabase(tables: [CachedTasks, PendingCommands])
class OfflineDatabase extends _$OfflineDatabase {
  OfflineDatabase(super.executor);
  OfflineDatabase.defaults()
    : super(driftDatabase(name: 'flutter_wms_offline'));

  @override
  int get schemaVersion => 1;

  Stream<List<WmsTask>> watchVisibleTasks() =>
      (select(cachedTasks)..where((row) => row.hiddenByCommand.equals(false)))
          .watch()
          .map((rows) => rows.map(_toTask).toList(growable: false));

  Future<List<WmsTask>> visibleTasks() async =>
      (await (select(
            cachedTasks,
          )..where((row) => row.hiddenByCommand.equals(false))).get())
          .map(_toTask)
          .toList(growable: false);

  Future<void> replaceFromServer(List<WmsTask> tasks) => transaction(() async {
    final pendingIds = (await select(
      pendingCommands,
    ).get()).map((row) => row.taskId).toSet();
    await batch((batch) {
      for (final task in tasks) {
        if (pendingIds.contains(task.id)) continue;
        batch.insert(
          cachedTasks,
          CachedTasksCompanion.insert(
            id: task.id,
            fromLocation: task.from,
            toLocation: task.to,
            status: task.status.name,
            cachedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
    final remoteIds = tasks.map((task) => task.id).toSet();
    final rows = await select(cachedTasks).get();
    for (final row in rows) {
      if (!remoteIds.contains(row.id) && !pendingIds.contains(row.id)) {
        await (delete(
          cachedTasks,
        )..where((item) => item.id.equals(row.id))).go();
      }
    }
  });

  Future<void> enqueueComplete(String taskId, String commandId) => transaction(
    () async {
      await into(pendingCommands).insert(
        PendingCommandsCompanion.insert(
          commandId: commandId,
          taskId: taskId,
          kind: 'completeTask',
          payloadJson: jsonEncode({'taskId': taskId}),
          createdAt: DateTime.now().toUtc(),
        ),
        mode: InsertMode.insertOrIgnore,
      );
      final updated =
          await (update(cachedTasks)..where((row) => row.id.equals(taskId)))
              .write(const CachedTasksCompanion(hiddenByCommand: Value(true)));
      if (updated == 0) {
        throw StateError('Cannot queue unknown task $taskId');
      }
    },
  );

  Future<List<PendingCommand>> commandsToSync() => (select(
    pendingCommands,
  )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();

  Future<void> acknowledge(String commandId, String taskId) =>
      transaction(() async {
        await (delete(
          pendingCommands,
        )..where((row) => row.commandId.equals(commandId))).go();
        await (delete(cachedTasks)..where((row) => row.id.equals(taskId))).go();
      });

  Future<void> recordFailure(String commandId, Object error) =>
      transaction(() async {
        final command = await (select(
          pendingCommands,
        )..where((row) => row.commandId.equals(commandId))).getSingleOrNull();
        if (command == null) return;
        await (update(
          pendingCommands,
        )..where((row) => row.commandId.equals(commandId))).write(
          PendingCommandsCompanion(
            attempts: Value(command.attempts + 1),
            lastError: Value(error.toString()),
          ),
        );
      });

  WmsTask _toTask(CachedTask row) => WmsTask(
    id: row.id,
    from: row.fromLocation,
    to: row.toLocation,
    status: TaskStatus.values.firstWhere((value) => value.name == row.status),
  );
}
