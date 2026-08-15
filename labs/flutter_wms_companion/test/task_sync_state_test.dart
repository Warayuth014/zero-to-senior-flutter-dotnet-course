import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/codegen/task_sync_state.dart';

TaskSyncState retryFailure(TaskSyncState state) => switch (state) {
  SyncFailed() => state.copyWith(message: 'timeout'),
  SyncIdle() || SyncRunning() => throw StateError('expected failure'),
};

String? failureMessage(TaskSyncState state) => switch (state) {
  SyncFailed(:final message) => message,
  SyncIdle() || SyncRunning() => null,
};

void main() {
  test('sealed union บังคับแยกสถานะและอ่าน payload ตาม case', () {
    const state = TaskSyncState.running(remaining: 3);

    expect(state.label, 'กำลังซิงก์ เหลือ 3');
    expect(switch (state) {
      SyncRunning(:final remaining) => remaining,
      SyncIdle() || SyncFailed() => 0,
    }, 3);
  });

  test('union equality และ copyWith ถูกสร้างตาม value', () {
    const first = TaskSyncState.failed(
      commandId: 'command-001',
      message: 'offline',
    );
    final retried = retryFailure(first);

    expect(
      first,
      const TaskSyncState.failed(commandId: 'command-001', message: 'offline'),
    );
    expect(failureMessage(retried), 'timeout');
    expect(failureMessage(first), 'offline');
  });
}
