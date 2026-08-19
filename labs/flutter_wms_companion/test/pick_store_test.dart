import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/state_basics/pick_repository.dart';
import 'package:flutter_wms_companion/state_basics/pick_store.dart';

/// ตัวปลอมที่เราควบคุมได้ทุกอย่าง — เวลา ผลลัพธ์ และจำนวนครั้งที่ถูกเรียก
class FakePickRepository implements PickRepository {
  FakePickRepository({this.lines = const []});

  List<PickLine> lines;

  /// ถ้าตั้งไว้ fetchLines จะรอ future นี้แทนที่จะคืนทันที
  Completer<List<PickLine>>? fetchGate;

  /// ถ้าตั้งไว้ markDone จะรอ future นี้
  Completer<void>? doneGate;

  PickException? fetchError;
  PickException? doneError;

  final List<String> fetchCalls = [];
  final List<String> doneCalls = [];
  final List<String> commandIds = [];

  @override
  Future<List<PickLine>> fetchLines() async {
    fetchCalls.add('fetch');
    final gate = fetchGate;
    if (gate != null) return gate.future;
    if (fetchError != null) throw fetchError!;
    return lines;
  }

  @override
  Future<void> markDone(String lineId, {required String commandId}) async {
    doneCalls.add(lineId);
    commandIds.add(commandId);
    final gate = doneGate;
    if (gate != null) return gate.future;
    if (doneError != null) throw doneError!;
  }
}

const _lines = [
  PickLine(id: 'L-1', palletCode: 'PAL-1001', quantity: 12),
  PickLine(id: 'L-2', palletCode: 'PAL-1002', quantity: 4),
];

void main() {
  group('load', () {
    test('สำเร็จแล้วได้สถานะ ready พร้อมข้อมูล', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);

      await store.load();

      expect(store.state, LoadState.ready);
      expect(store.lines, hasLength(2));
      expect(store.remainingCount, 2);
    });

    test('ไม่มีข้อมูลได้สถานะ empty ไม่ใช่ ready', () async {
      final repo = FakePickRepository(lines: const []);
      final store = PickStore(repository: repo);

      await store.load();

      expect(store.state, LoadState.empty);
    });

    test('ล้มเหลวได้สถานะ failed ไม่ใช่ empty', () async {
      final repo = FakePickRepository()
        ..fetchError = const PickException('เชื่อมต่อไม่ได้');
      final store = PickStore(repository: repo);

      await store.load();

      expect(store.state, LoadState.failed);
      expect(store.errorMessage, 'เชื่อมต่อไม่ได้');
    });

    test('ผลของคำขอเก่าที่มาช้าต้องไม่ทับคำขอใหม่', () async {
      final repo = FakePickRepository();
      final store = PickStore(repository: repo);

      // คำขอที่ 1 ค้างไว้
      final slow = Completer<List<PickLine>>();
      repo.fetchGate = slow;
      final first = store.load();

      // คำขอที่ 2 เสร็จก่อน
      final fast = Completer<List<PickLine>>();
      repo.fetchGate = fast;
      final second = store.load();
      fast.complete(const [
        PickLine(id: 'L-9', palletCode: 'PAL-9999', quantity: 1),
      ]);
      await second;

      expect(store.lines.single.id, 'L-9');

      // ผลของคำขอที่ 1 กลับมาทีหลัง ต้องถูกทิ้ง
      slow.complete(_lines);
      await first;

      expect(store.lines.single.id, 'L-9');
    });
  });

  group('markDone', () {
    test('แสดงผลทันทีก่อน server ตอบ', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);
      await store.load();

      final gate = Completer<void>();
      repo.doneGate = gate;
      final pending = store.markDone('L-1');

      // ยังไม่ตอบ แต่หน้าจอควรเห็นว่าเสร็จแล้ว
      expect(store.lines.first.done, isTrue);
      expect(store.remainingCount, 1);
      expect(store.isBusy('L-1'), isTrue);

      gate.complete();
      await pending;

      expect(store.isBusy('L-1'), isFalse);
      expect(store.lines.first.done, isTrue);
    });

    test('ล้มเหลวแบบรู้ผล ต้องย้อนกลับ', () async {
      final repo = FakePickRepository(lines: _lines)
        ..doneError = const PickException('งานนี้ถูกยกเลิกแล้ว');
      final store = PickStore(repository: repo);
      await store.load();

      await store.markDone('L-1');

      expect(store.lines.first.done, isFalse); // ย้อนกลับแล้ว
      expect(store.remainingCount, 2);
      expect(store.errorMessage, 'งานนี้ถูกยกเลิกแล้ว');
    });

    test('ไม่รู้ผล ต้องไม่ย้อนกลับเอง แต่ไปถาม server แทน', () async {
      final repo = FakePickRepository(lines: _lines)
        ..doneError = const PickException('หมดเวลารอ', outcomeUnknown: true);
      final store = PickStore(repository: repo);
      await store.load();

      // ครั้งถัดไปที่โหลด server บอกว่า L-1 เสร็จแล้วจริง
      repo.lines = [_lines.first.copyWith(done: true), _lines[1]];

      await store.markDone('L-1');

      expect(repo.fetchCalls, hasLength(2)); // โหลดซ้ำเพื่อตรวจสอบ
      expect(store.lines.first.done, isTrue);
    });

    test('กดซ้ำระหว่างที่ยังส่งไม่เสร็จ ไม่ส่งซ้ำ', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);
      await store.load();

      final gate = Completer<void>();
      repo.doneGate = gate;

      final first = store.markDone('L-1');
      await store.markDone('L-1');
      await store.markDone('L-1');

      gate.complete();
      await first;

      expect(repo.doneCalls, ['L-1']);
    });

    test('ไม่รู้ผลแล้วลองใหม่ ต้องใช้รหัสคำสั่งเดิม เพื่อไม่ให้บันทึกซ้ำ', () async {
      var counter = 0;
      final repo = FakePickRepository(lines: _lines)
        ..doneError = const PickException('หมดเวลารอ', outcomeUnknown: true);
      final store = PickStore(
        repository: repo,
        createCommandId: () => 'cmd-${counter++}',
      );
      await store.load();

      await store.markDone('L-1');
      await store.markDone('L-1');

      // ทั้งสองครั้งเป็นคำสั่งเดียวกัน server จึงเห็นรหัสเดิมและไม่บันทึกซ้ำ
      expect(repo.commandIds, ['cmd-0', 'cmd-0']);
    });

    test('รู้แน่ว่าล้มเหลว การลองใหม่คือเจตนาใหม่ จึงใช้รหัสใหม่', () async {
      var counter = 0;
      final repo = FakePickRepository(lines: _lines)
        ..doneError = const PickException('งานนี้ถูกยกเลิกแล้ว');
      final store = PickStore(
        repository: repo,
        createCommandId: () => 'cmd-${counter++}',
      );
      await store.load();

      await store.markDone('L-1');
      await store.markDone('L-1');

      expect(repo.commandIds, ['cmd-0', 'cmd-1']);
    });

    test('สำเร็จแล้วครั้งถัดไปใช้รหัสใหม่', () async {
      var counter = 0;
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(
        repository: repo,
        createCommandId: () => 'cmd-${counter++}',
      );
      await store.load();

      await store.markDone('L-1');
      await store.markDone('L-2');

      expect(repo.commandIds, ['cmd-0', 'cmd-1']);
    });

    test('บรรทัดที่เสร็จแล้วสั่งซ้ำไม่ได้', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);
      await store.load();

      await store.markDone('L-1');
      await store.markDone('L-1');

      expect(repo.doneCalls, ['L-1']);
    });
  });

  group('ค่าที่คำนวณได้', () {
    test('allDone เป็นจริงเมื่อไม่มีอะไรเหลือ', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);
      await store.load();

      expect(store.allDone, isFalse);

      await store.markDone('L-1');
      await store.markDone('L-2');

      expect(store.remainingCount, 0);
      expect(store.allDone, isTrue);
    });

    test('รายการที่คืนออกไปแก้ไม่ได้', () async {
      final repo = FakePickRepository(lines: _lines);
      final store = PickStore(repository: repo);
      await store.load();

      expect(
        () => store.lines.add(
          const PickLine(id: 'X', palletCode: 'X', quantity: 1),
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('polling', () {
    test('ดึงซ้ำตามรอบ และหยุดเมื่อสั่งหยุด', () {
      fakeAsync((async) {
        final repo = FakePickRepository(lines: _lines);
        final store = PickStore(repository: repo);

        store.startPolling(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 35));

        expect(repo.fetchCalls, hasLength(3));

        store.stopPolling();
        async.elapse(const Duration(seconds: 30));

        expect(repo.fetchCalls, hasLength(3)); // ไม่เพิ่มอีก
      });
    });

    test('dispose หยุด polling ให้เอง', () {
      fakeAsync((async) {
        final repo = FakePickRepository(lines: _lines);
        final store = PickStore(repository: repo);

        store.startPolling(const Duration(seconds: 10));
        async.elapse(const Duration(seconds: 15));
        final callsBefore = repo.fetchCalls.length;

        store.dispose();
        async.elapse(const Duration(seconds: 60));

        expect(repo.fetchCalls, hasLength(callsBefore));
      });
    });
  });
}
