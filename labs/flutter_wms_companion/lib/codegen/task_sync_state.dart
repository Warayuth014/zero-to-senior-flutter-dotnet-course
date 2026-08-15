import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_sync_state.freezed.dart';

@freezed
sealed class TaskSyncState with _$TaskSyncState {
  const TaskSyncState._();

  const factory TaskSyncState.idle() = SyncIdle;

  const factory TaskSyncState.running({required int remaining}) = SyncRunning;

  const factory TaskSyncState.failed({
    required String commandId,
    required String message,
  }) = SyncFailed;

  String get label => switch (this) {
    SyncIdle() => 'พร้อมซิงก์',
    SyncRunning(:final remaining) => 'กำลังซิงก์ เหลือ $remaining',
    SyncFailed(:final commandId, :final message) =>
      'ซิงก์ $commandId ไม่สำเร็จ · $message',
  };
}
