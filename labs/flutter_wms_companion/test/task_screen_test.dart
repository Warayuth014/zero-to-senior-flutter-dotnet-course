import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/task_screen.dart';
import 'package:flutter_wms_companion/features/tasks/task_store.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';

class ScreenTaskRepository implements TaskRepository {
  final tasks = <WmsTask>[
    const WmsTask(
      id: 'TASK-001',
      from: 'A-01',
      to: 'PACK-01',
      status: TaskStatus.waiting,
    ),
  ];

  @override
  Future<List<WmsTask>> fetchOpen() async => List.of(tasks);

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    tasks.removeWhere((task) => task.id == id);
    return TaskCompletion(
      id: id,
      alreadyCompleted: false,
      correlationId: 'widget-test',
    );
  }
}

void main() {
  testWidgets('ผู้ใช้ต้องยืนยันก่อนปิด task และเห็นผลลัพธ์', (tester) async {
    final store = TaskStore(
      ScreenTaskRepository(),
      createCommandId: (_) => 'widget-command',
    );
    await tester.pumpWidget(MaterialApp(home: TaskScreen(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('TASK-001'), findsOneWidget);
    await tester.tap(find.text('เสร็จงาน'));
    await tester.pumpAndSettle();
    expect(find.text('ยืนยันปิด TASK-001?'), findsOneWidget);

    await tester.tap(find.text('ยืนยัน'));
    await tester.pumpAndSettle();

    expect(find.text('ไม่มีงานค้าง'), findsOneWidget);
    expect(find.textContaining('widget-test'), findsOneWidget);
  });
}
