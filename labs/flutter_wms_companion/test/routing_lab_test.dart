import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/features/tasks/task_repository.dart';
import 'package:flutter_wms_companion/features/tasks/wms_task.dart';
import 'package:flutter_wms_companion/routing/routing_app.dart';
import 'package:flutter_wms_companion/routing/routing_session.dart';

class RoutingFakeRepository implements TaskRepository {
  final tasks = <WmsTask>[
    const WmsTask(
      id: 'TASK-001',
      from: 'A-01',
      to: 'PACK-01',
      status: TaskStatus.waiting,
    ),
    const WmsTask(
      id: 'TASK-002',
      from: 'B-05',
      to: 'OUT-02',
      status: TaskStatus.working,
    ),
  ];

  @override
  Future<List<WmsTask>> fetchOpen() async => List.of(tasks);

  @override
  Future<TaskCompletion> complete(
    String id, {
    required String commandId,
  }) async => TaskCompletion(
    id: id,
    alreadyCompleted: false,
    correlationId: 'routing-test',
  );
}

void main() {
  test('safeLocalLocation รับเฉพาะ internal URI', () {
    expect(safeLocalLocation('/tasks/TASK-001?source=email'), isNotNull);
    expect(safeLocalLocation('https://evil.example/tasks'), isNull);
    expect(safeLocalLocation('//evil.example/tasks'), isNull);
    expect(safeLocalLocation('/login'), isNull);
  });

  testWidgets('protected deep link กลับปลายทางเดิมหลัง login', (tester) async {
    final session = RoutingSession();
    await tester.pumpWidget(
      RoutingLabApp(
        session: session,
        repository: RoutingFakeRepository(),
        initialLocation: '/tasks/TASK-001?source=email',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('เส้นทางนี้ต้องเข้าสู่ระบบ'), findsOneWidget);
    expect(
      find.text('หลัง login จะไป: /tasks/TASK-001?source=email'),
      findsOneWidget,
    );

    await tester.tap(find.text('เข้าสู่ระบบแบบ Lab'));
    await tester.pumpAndSettle();
    expect(find.text('Task TASK-001'), findsOneWidget);
    expect(find.text('Query source: email'), findsOneWidget);
  });

  testWidgets('query filter เป็นส่วนหนึ่งของ URL และผลลัพธ์', (tester) async {
    await tester.pumpWidget(
      RoutingLabApp(
        session: RoutingSession(authenticated: true),
        repository: RoutingFakeRepository(),
        initialLocation: '/tasks?status=waiting',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('filter: waiting'), findsOneWidget);
    expect(find.text('TASK-001'), findsOneWidget);
    expect(find.text('TASK-002'), findsNothing);
  });

  testWidgets('StatefulShellRoute รักษา detail stack ของ Tasks', (
    tester,
  ) async {
    await tester.pumpWidget(
      RoutingLabApp(
        session: RoutingSession(authenticated: true),
        repository: RoutingFakeRepository(),
        initialLocation: '/tasks/TASK-001',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Task TASK-001'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Warehouse Home'), findsOneWidget);

    await tester.tap(find.text('Tasks'));
    await tester.pumpAndSettle();
    expect(find.text('Task TASK-001'), findsOneWidget);
  });

  testWidgets('root navigator scanner คืน result กลับ detail', (tester) async {
    await tester.pumpWidget(
      RoutingLabApp(
        session: RoutingSession(authenticated: true),
        repository: RoutingFakeRepository(),
        initialLocation: '/tasks/TASK-001',
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('เปิด scanner แบบ full screen'));
    await tester.pumpAndSettle();
    expect(find.text('Scanner · TASK-001'), findsOneWidget);
    expect(find.text('Home'), findsNothing);

    await tester.tap(find.text('จำลองสแกนสำเร็จ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PALLET-DEMO-001'), findsOneWidget);
  });
}
