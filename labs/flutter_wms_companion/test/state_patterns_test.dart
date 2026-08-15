import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';
import 'package:flutter_wms_companion/state_patterns/bloc/task_cubit.dart';
import 'package:flutter_wms_companion/state_patterns/provider/provider_task_panel.dart';
import 'package:flutter_wms_companion/state_patterns/riverpod/riverpod_task_controller.dart';

class PatternFakeRepository implements TaskRepository {
  PatternFakeRepository()
    : tasks = [
        const WmsTask(
          id: 'TASK-001',
          from: 'A-01',
          to: 'PACK-01',
          status: TaskStatus.waiting,
        ),
      ];

  final List<WmsTask> tasks;
  int completeCalls = 0;

  @override
  Future<List<WmsTask>> fetchOpen() async => List.of(tasks);

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async {
    completeCalls++;
    tasks.removeWhere((task) => task.id == id);
    return TaskCompletion(
      id: id,
      alreadyCompleted: false,
      correlationId: 'pattern-test',
    );
  }
}

void main() {
  test('Cubit load และ complete ใช้ immutable state', () async {
    final repository = PatternFakeRepository();
    final cubit = TaskCubit(
      repository,
      createCommandId: (_) => 'cubit-command',
    );
    addTearDown(cubit.close);

    await cubit.load();
    final loadedState = cubit.state;
    expect(loadedState.tasks.single.id, 'TASK-001');

    await cubit.complete(loadedState.tasks.single);
    expect(cubit.state.tasks, isEmpty);
    expect(cubit.state.message, contains('pattern-test'));
  });

  test('Riverpod override repository และทดสอบโดยไม่ใช้ BuildContext', () async {
    final repository = PatternFakeRepository();
    final container = ProviderContainer(
      overrides: [taskRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final loaded = await container.read(riverpodTaskProvider.future);
    expect(loaded.tasks.single.id, 'TASK-001');

    await container
        .read(riverpodTaskProvider.notifier)
        .complete(loaded.tasks.single);
    expect(container.read(riverpodTaskProvider).requireValue.tasks, isEmpty);
  });

  testWidgets('Provider สร้างและ dispose TaskStore ตาม widget ownership', (
    tester,
  ) async {
    final repository = PatternFakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProviderTaskPanel(repository: repository)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Provider + ChangeNotifier'), findsOneWidget);
    expect(find.text('1 tasks'), findsOneWidget);
    expect(find.text('TASK-001'), findsOneWidget);

    await tester.tap(find.text('เสร็จงาน'));
    await tester.pumpAndSettle();
    expect(find.text('0 tasks'), findsOneWidget);
    expect(repository.completeCalls, 1);
  });
}
