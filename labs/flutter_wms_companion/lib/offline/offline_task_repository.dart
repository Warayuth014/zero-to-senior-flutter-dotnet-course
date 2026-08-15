import '../features/tasks/task_repository.dart';
import '../features/tasks/wms_task.dart';
import 'offline_database.dart';

class OfflineTaskRepository implements TaskRepository {
  OfflineTaskRepository({required this.remote, required this.database});

  final TaskRepository remote;
  final OfflineDatabase database;

  @override
  Future<List<WmsTask>> fetchOpen() async {
    late final List<WmsTask> tasks;
    try {
      tasks = await remote.fetchOpen();
    } catch (_) {
      final cached = await database.visibleTasks();
      if (cached.isEmpty) rethrow;
      return cached;
    }
    await database.replaceFromServer(tasks);
    return database.visibleTasks();
  }

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    await database.enqueueComplete(id, commandId);
    return TaskCompletion(
      id: id,
      alreadyCompleted: false,
      correlationId: 'queued:$commandId',
    );
  }

  Future<int> syncPending() async {
    var synced = 0;
    for (final command in await database.commandsToSync()) {
      try {
        await remote.complete(command.taskId, commandId: command.commandId);
        await database.acknowledge(command.commandId, command.taskId);
        synced++;
      } catch (error) {
        await database.recordFailure(command.commandId, error);
      }
    }
    return synced;
  }
}
