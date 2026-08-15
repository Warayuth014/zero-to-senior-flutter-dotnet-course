import '../features/tasks/wms_task.dart';

class TaskPatternState {
  TaskPatternState({
    List<WmsTask> tasks = const [],
    this.refreshing = false,
    Set<String> busyTaskIds = const {},
    this.error,
    this.message,
  }) : tasks = List.unmodifiable(tasks),
       busyTaskIds = Set.unmodifiable(busyTaskIds);

  static const _unset = Object();

  final List<WmsTask> tasks;
  final bool refreshing;
  final Set<String> busyTaskIds;
  final String? error;
  final String? message;

  bool isBusy(String taskId) => busyTaskIds.contains(taskId);

  TaskPatternState copyWith({
    List<WmsTask>? tasks,
    bool? refreshing,
    Set<String>? busyTaskIds,
    Object? error = _unset,
    Object? message = _unset,
  }) => TaskPatternState(
    tasks: List.unmodifiable(tasks ?? this.tasks),
    refreshing: refreshing ?? this.refreshing,
    busyTaskIds: Set.unmodifiable(busyTaskIds ?? this.busyTaskIds),
    error: identical(error, _unset) ? this.error : error as String?,
    message: identical(message, _unset) ? this.message : message as String?,
  );
}
