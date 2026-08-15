import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/api_client.dart';
import '../../features/tasks/task_repository.dart';
import '../../features/tasks/wms_task.dart';
import '../task_pattern_state.dart';

class TaskCubit extends Cubit<TaskPatternState> {
  TaskCubit(this.repository, {String Function(String taskId)? createCommandId})
    : _createCommandId =
          createCommandId ??
          ((taskId) => '$taskId-${DateTime.now().microsecondsSinceEpoch}'),
      super(TaskPatternState(refreshing: true));

  final TaskRepository repository;
  final String Function(String taskId) _createCommandId;

  Future<void> load() async {
    emit(state.copyWith(refreshing: true, error: null));
    try {
      emit(
        state.copyWith(
          tasks: await repository.fetchOpen(),
          refreshing: false,
          error: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(refreshing: false, error: Error.safeToString(error)));
    }
  }

  Future<void> complete(WmsTask task) async {
    if (state.isBusy(task.id)) return;
    emit(
      state.copyWith(
        busyTaskIds: {...state.busyTaskIds, task.id},
        error: null,
        message: null,
      ),
    );
    try {
      final result = await repository.complete(
        task.id,
        commandId: _createCommandId(task.id),
      );
      emit(
        state.copyWith(
          tasks: state.tasks.where((item) => item.id != task.id).toList(),
          busyTaskIds: {...state.busyTaskIds}..remove(task.id),
          message: 'ปิด ${task.id} สำเร็จ · ${result.correlationId}',
          error: null,
        ),
      );
    } on ApiException catch (error) {
      if (error.outcomeUnknown) {
        await _reconcile(task, error.message);
      } else {
        emit(
          state.copyWith(
            busyTaskIds: {...state.busyTaskIds}..remove(task.id),
            error: error.message,
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          busyTaskIds: {...state.busyTaskIds}..remove(task.id),
          error: Error.safeToString(error),
        ),
      );
    }
  }

  Future<void> _reconcile(WmsTask task, String reason) async {
    try {
      final latest = await repository.fetchOpen();
      final stillOpen = latest.any((item) => item.id == task.id);
      emit(
        state.copyWith(
          tasks: latest,
          busyTaskIds: {...state.busyTaskIds}..remove(task.id),
          error: stillOpen
              ? 'ยังยืนยันผลของ ${task.id} ไม่ได้ · $reason'
              : null,
          message: stillOpen
              ? null
              : '${task.id} ไม่อยู่ในงานค้างแล้ว หลังตรวจสอบซ้ำ',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          busyTaskIds: {...state.busyTaskIds}..remove(task.id),
          error:
              'ตรวจสอบ ${task.id} ซ้ำไม่สำเร็จ · ${Error.safeToString(error)}',
        ),
      );
    }
  }
}
