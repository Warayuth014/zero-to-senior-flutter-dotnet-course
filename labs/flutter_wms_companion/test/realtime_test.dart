import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/realtime_lab/hub_events.dart';
import 'package:flutter_wms_companion/realtime_lab/live_task.dart';
import 'package:flutter_wms_companion/realtime_lab/live_task_store.dart';
import 'package:flutter_wms_companion/realtime_lab/realtime_client.dart';

LiveTask task(
  String id, {
  LiveTaskStatus status = LiveTaskStatus.waiting,
  int version = 1,
}) => LiveTask(id: id, status: status, version: version);

/// repository ที่คุมได้ว่าจะตอบอะไร และนับว่าถูกเรียกกี่ครั้ง
class FakeTaskRepository implements LiveTaskRepository {
  List<LiveTask> result = const [];
  int fetchCalls = 0;
  Object? throwOnFetch;

  @override
  Future<List<LiveTask>> fetchOpen() async {
    fetchCalls++;
    if (throwOnFetch case final error?) throw error;
    return result;
  }
}

void main() {
  group('แปลงเหตุการณ์ดิบ', () {
    test('เหตุการณ์ที่รู้จักและข้อมูลถูก แปลงได้', () {
      final event = decodeHubEvent('TaskDispatched', [
        {'taskId': 'T-1', 'assignee': 'AGV-02', 'version': 3},
      ]);

      expect(event, isA<TaskDispatched>());
      final dispatched = event as TaskDispatched;
      expect(dispatched.taskId, 'T-1');
      expect(dispatched.assignee, 'AGV-02');
      expect(dispatched.version, 3);
    });

    test('รับ Map ที่ไม่ได้ระบุชนิดจาก JSON ที่ถอดรหัสแล้ว', () {
      final raw = <dynamic, dynamic>{'taskId': 'T-1', 'version': 2};
      expect(decodeHubEvent('TaskCompleted', [raw]), isA<TaskCompleted>());
    });

    test('เลขที่มาเป็น double แต่เป็นจำนวนเต็ม ใช้ได้', () {
      // JSON ไม่แยก int กับ double — 3 กับ 3.0 คือเลขเดียวกัน
      final event = decodeHubEvent('TaskCompleted', [
        {'taskId': 'T-1', 'version': 3.0},
      ]);
      expect((event as TaskCompleted).version, 3);
    });

    test('เหตุการณ์ที่แอปยังไม่รู้จัก ไม่ใช่ความผิดพลาด', () {
      final event = decodeHubEvent('SomethingNewInV4', [
        {'anything': true},
      ]);
      expect(event, isA<UnknownHubEvent>());
      expect(event.name, 'SomethingNewInV4');
    });

    test('ข้อมูลผิดสัญญา ได้เหตุการณ์ที่บอกว่าผิดตรงไหน', () {
      final event = decodeHubEvent('TaskDispatched', [
        {'taskId': 'T-1', 'assignee': 'AGV-02'}, // ไม่มี version
      ]);

      expect(event, isA<MalformedHubEvent>());
      expect((event as MalformedHubEvent).reason, contains('version'));
    });

    test('ไม่โยนไม่ว่าจะส่งอะไรมา', () {
      // ตัวรับเหตุการณ์ทำงานอยู่เบื้องหลัง ถ้าโยนขึ้นไปการเชื่อมต่อจะหลุด
      // แล้วผู้ใช้จะไม่ได้รับเหตุการณ์อีกเลยทั้งกะ
      final inputs = <List<Object?>?>[
        null,
        [],
        ['ข้อความ ไม่ใช่ object'],
        [42],
        [
          {'taskId': 123, 'version': 'สาม'},
        ],
      ];

      for (final args in inputs) {
        expect(() => decodeHubEvent('TaskCompleted', args), returnsNormally);
        expect(decodeHubEvent('TaskCompleted', args), isA<MalformedHubEvent>());
      }
    });
  });

  group('การเชื่อมต่อที่ใช้ร่วมกัน', () {
    late InMemoryRealtimeClient inner;
    late SharedRealtimeClient shared;

    setUp(() {
      inner = InMemoryRealtimeClient();
      shared = SharedRealtimeClient(inner);
    });

    tearDown(() => inner.dispose());

    test('สามจอขอใช้ ต่อจริงครั้งเดียว', () async {
      await shared.acquire();
      await shared.acquire();
      await shared.acquire();

      expect(inner.connectCalls, 1);
      expect(shared.userCount, 3);
    });

    test('ตัดจริงเมื่อจอสุดท้ายปล่อย', () async {
      await shared.acquire();
      await shared.acquire();

      await shared.release();
      expect(inner.disconnectCalls, 0, reason: 'ยังมีอีกจอใช้อยู่');

      await shared.release();
      expect(inner.disconnectCalls, 1);
    });

    test('ปล่อยเกินจำนวน ต้องไม่ทำให้ตัวนับติดลบ', () async {
      await shared.acquire();
      await shared.release();
      await shared.release(); // เรียกเกิน — เป็นบั๊กที่พบบ่อย
      await shared.release();

      expect(shared.userCount, 0);

      // ถ้าตัวนับติดลบ การขอใช้ครั้งถัดไปจะไม่ต่อจริง แล้วจอจะเงียบ
      await shared.acquire();
      expect(inner.connectCalls, 2);
    });
  });

  group('LiveTaskStore', () {
    late InMemoryRealtimeClient inner;
    late SharedRealtimeClient shared;
    late FakeTaskRepository repository;
    late LiveTaskStore store;

    setUp(() {
      inner = InMemoryRealtimeClient();
      shared = SharedRealtimeClient(inner);
      repository = FakeTaskRepository();
      store = LiveTaskStore(repository: repository, client: shared);
    });

    tearDown(() => inner.dispose());

    test('เริ่มทำงานแล้วต่อเรียลไทม์และโหลดครั้งแรก', () async {
      repository.result = [task('T-1'), task('T-2')];

      await store.start();

      expect(inner.connectCalls, 1);
      expect(repository.fetchCalls, 1);
      expect(store.tasks, hasLength(2));
      expect(store.status, RealtimeStatus.connected);
      store.dispose();
    });

    test('เหตุการณ์เปลี่ยนสถานะโดยไม่ต้องยิง HTTP', () async {
      repository.result = [task('T-1')];
      await store.start();
      final callsAfterLoad = repository.fetchCalls;

      inner.emit(const TaskDispatched(
        taskId: 'T-1',
        assignee: 'AGV-02',
        version: 2,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(store.tasks.single.status, LiveTaskStatus.dispatched);
      expect(store.tasks.single.assignee, 'AGV-02');
      // นี่คือเหตุผลทั้งหมดที่ยอมทำเรียลไทม์ — ไม่มีคำขอเพิ่มเลย
      expect(repository.fetchCalls, callsAfterLoad);
      store.dispose();
    });

    test('เหตุการณ์เก่าที่มาถึงช้า ต้องไม่ทับของใหม่', () async {
      repository.result = [task('T-1', version: 5)];
      await store.start();

      // เหตุการณ์รุ่น 3 มาถึงหลังจากที่เรารู้รุ่น 5 แล้ว
      inner.emit(const TaskCompleted(taskId: 'T-1', version: 3));
      await Future<void>.delayed(Duration.zero);

      expect(store.tasks.single.status, LiveTaskStatus.waiting);
      expect(store.tasks.single.version, 5);
      store.dispose();
    });

    test('เหตุการณ์ซ้ำรุ่นเดิม ต้องไม่ทำอะไร', () async {
      repository.result = [task('T-1', version: 2)];
      await store.start();

      inner.emit(const TaskCompleted(taskId: 'T-1', version: 2));
      await Future<void>.delayed(Duration.zero);

      expect(store.tasks.single.status, LiveTaskStatus.waiting);
      store.dispose();
    });

    test('งานที่เสร็จแล้วและไม่เคยรู้จัก ไม่ต้องเพิ่มเข้าลิสต์งานค้าง', () async {
      repository.result = [task('T-1')];
      await store.start();

      inner.emit(const TaskCompleted(taskId: 'T-99', version: 1));
      await Future<void>.delayed(Duration.zero);

      expect(store.tasks.map((t) => t.id), ['T-1']);
      store.dispose();
    });

    test('งานใหม่ที่ถูกจ่ายออกไป ต้องโผล่ในลิสต์', () async {
      repository.result = [task('T-1')];
      await store.start();

      inner.emit(const TaskDispatched(
        taskId: 'T-2',
        assignee: 'FORK-01',
        version: 1,
      ));
      await Future<void>.delayed(Duration.zero);

      expect(store.tasks.map((t) => t.id), containsAll(['T-1', 'T-2']));
      store.dispose();
    });

    test('เหตุการณ์เสียถูกนับไว้ แต่ไม่ทำให้สถานะเพี้ยน', () async {
      repository.result = [task('T-1')];
      await store.start();

      inner.emitRaw('TaskCompleted', [
        {'taskId': 'T-1'}, // ไม่มี version
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(store.malformedEventCount, 1);
      expect(store.tasks.single.status, LiveTaskStatus.waiting);
      store.dispose();
    });

    test('ต่อกลับได้หลังหลุด ต้องโหลดใหม่เพื่ออุดช่วงที่ขาดไป', () async {
      repository.result = [task('T-1')];
      await store.start();
      final callsBefore = repository.fetchCalls;

      inner.simulateDrop();
      await Future<void>.delayed(Duration.zero);
      // ระหว่างนี้เซิร์ฟเวอร์ส่งเหตุการณ์ไปหลายอันที่เราไม่ได้รับ

      inner.simulateReconnected();
      await Future<void>.delayed(Duration.zero);

      expect(repository.fetchCalls, callsBefore + 1);
      store.dispose();
    });

    test('หลุดแล้วเริ่มถามซ้ำ ต่อกลับได้แล้วหยุด', () {
      fakeAsync((async) {
        repository.result = [task('T-1')];
        unawaited(store.start());
        async.flushMicrotasks();
        expect(store.isPolling, isFalse, reason: 'ต่อได้อยู่ ไม่ต้องถามซ้ำ');

        inner.simulateDrop();
        async.flushMicrotasks();
        expect(store.isPolling, isTrue);

        final callsBefore = repository.fetchCalls;
        async.elapse(const Duration(seconds: 45));
        expect(repository.fetchCalls, callsBefore + 3);

        inner.simulateReconnected();
        async.flushMicrotasks();
        expect(store.isPolling, isFalse);

        // หลังหยุดแล้วต้องไม่มีคำขอเพิ่มจากตัวจับเวลาอีก
        // (+1 มาจากการโหลดอุดช่วงที่ขาด)
        final callsAfterReconnect = repository.fetchCalls;
        async.elapse(const Duration(minutes: 5));
        expect(repository.fetchCalls, callsAfterReconnect);

        store.dispose();
        async.flushTimers();
      });
    });

    test('ทิ้ง store แล้วตัวจับเวลาต้องหยุด', () {
      fakeAsync((async) {
        unawaited(store.start());
        async.flushMicrotasks();
        inner.simulateDrop();
        async.flushMicrotasks();
        expect(store.isPolling, isTrue);

        store.dispose();
        final callsAtDispose = repository.fetchCalls;

        async.elapse(const Duration(minutes: 10));
        expect(repository.fetchCalls, callsAtDispose);
      });
    });

    test('ทิ้ง store แล้วเหตุการณ์ที่มาทีหลังต้องไม่ถูกจัดการ', () async {
      repository.result = [task('T-1')];
      await store.start();
      store.dispose();

      // ถ้าไม่ยกเลิกการฟัง บรรทัดนี้จะทำให้ ChangeNotifier ที่ถูกทิ้งแล้ว
      // ถูกเรียก notifyListeners ซึ่งโยนข้อผิดพลาด
      inner.emit(const TaskCompleted(taskId: 'T-1', version: 9));
      await Future<void>.delayed(Duration.zero);

      expect(store.malformedEventCount, 0);
    });

    test('ทิ้ง store แล้วปล่อยการเชื่อมต่อที่ใช้ร่วมกัน', () async {
      await store.start();
      expect(shared.userCount, 1);

      store.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(shared.userCount, 0);
      expect(inner.disconnectCalls, 1);
    });

    test('โหลดล้มเหลว ต้องเก็บข้อความไว้แสดง ไม่ใช่พัง', () async {
      repository.throwOnFetch = Exception('เชื่อมต่อไม่ได้');

      await store.start();

      expect(store.error, isNotNull);
      expect(store.loading, isFalse);
      store.dispose();
    });

    test('ต่อเรียลไทม์ไม่ได้ตั้งแต่แรก ต้องถามซ้ำแทน', () {
      fakeAsync((async) {
        inner.failOnConnect = true;
        repository.result = [task('T-1')];

        unawaited(store.start());
        async.flushMicrotasks();

        expect(store.status, RealtimeStatus.disconnected);
        expect(store.isPolling, isTrue, reason: 'ต้องมีทางสำรอง');

        final callsBefore = repository.fetchCalls;
        async.elapse(const Duration(seconds: 30));
        expect(repository.fetchCalls, greaterThan(callsBefore));

        store.dispose();
        async.flushTimers();
      });
    });
  });
}
