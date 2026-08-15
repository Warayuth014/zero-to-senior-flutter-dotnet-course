import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../features/tasks/task_repository.dart';
import '../../features/tasks/wms_task.dart';
import '../task_pattern_state.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => throw StateError('ต้อง override taskRepositoryProvider'),
);

final riverpodTaskProvider =
    AsyncNotifierProvider<RiverpodTaskController, TaskPatternState>(
      RiverpodTaskController.new,
    );

class RiverpodTaskController extends AsyncNotifier<TaskPatternState> {
  TaskRepository get _repository => ref.read(taskRepositoryProvider);

  @override
  Future<TaskPatternState> build() async =>
      TaskPatternState(tasks: await _repository.fetchOpen());

  Future<void> refresh() async {
    final current = state.requireValue;
    state = AsyncData(current.copyWith(refreshing: true, error: null));
    try {
      final tasks = await _repository.fetchOpen();
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(tasks: tasks, refreshing: false, error: null),
      );
    } catch (error) {
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(refreshing: false, error: Error.safeToString(error)),
      );
    }
  }

  Future<void> complete(WmsTask task) async {
    final current = state.requireValue;
    if (current.isBusy(task.id)) return;
    state = AsyncData(
      current.copyWith(
        busyTaskIds: {...current.busyTaskIds, task.id},
        error: null,
        message: null,
      ),
    );
    try {
      final result = await _repository.complete(
        task.id,
        commandId: '$task.id-${DateTime.now().microsecondsSinceEpoch}',
      );
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          tasks: latest.tasks.where((item) => item.id != task.id).toList(),
          busyTaskIds: {...latest.busyTaskIds}..remove(task.id),
          message: 'ปิด ${task.id} สำเร็จ · ${result.correlationId}',
          error: null,
        ),
      );
    } on ApiException catch (error) {
      if (error.outcomeUnknown) {
        await _reconcile(task, error.message);
      } else {
        final latest = state.requireValue;
        state = AsyncData(
          latest.copyWith(
            busyTaskIds: {...latest.busyTaskIds}..remove(task.id),
            error: error.message,
          ),
        );
      }
    } catch (error) {
      final latest = state.requireValue;
      state = AsyncData(
        latest.copyWith(
          busyTaskIds: {...latest.busyTaskIds}..remove(task.id),
          error: Error.safeToString(error),
        ),
      );
    }
  }

  Future<void> _reconcile(WmsTask task, String reason) async {
    try {
      final latest = await _repository.fetchOpen();
      final stillOpen = latest.any((item) => item.id == task.id);
      final current = state.requireValue;
      state = AsyncData(
        current.copyWith(
          tasks: latest,
          busyTaskIds: {...current.busyTaskIds}..remove(task.id),
          error: stillOpen
              ? 'ยังยืนยันผลของ ${task.id} ไม่ได้ · $reason'
              : null,
          message: stillOpen
              ? null
              : '${task.id} ไม่อยู่ในงานค้างแล้ว หลังตรวจสอบซ้ำ',
        ),
      );
    } catch (error) {
      final current = state.requireValue;
      state = AsyncData(
        current.copyWith(
          busyTaskIds: {...current.busyTaskIds}..remove(task.id),
          error:
              'ตรวจสอบ ${task.id} ซ้ำไม่สำเร็จ · ${Error.safeToString(error)}',
        ),
      );
    }
  }
}
