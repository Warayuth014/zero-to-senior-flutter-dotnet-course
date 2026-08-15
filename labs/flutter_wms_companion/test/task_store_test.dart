import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/task_store.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';

class FakeTaskRepository implements TaskRepository {
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
  Future<void> complete(String id) async {
    tasks.removeWhere((task) => task.id == id);
  }
}

void main() {
  test('load และ complete อัปเดต single source of truth', () async {
    final store = TaskStore(FakeTaskRepository());
    await store.load();
    expect(store.tasks.single.id, 'TASK-001');

    await store.complete(store.tasks.single);
    expect(store.tasks, isEmpty);
    expect(store.error, isNull);
  });
}
