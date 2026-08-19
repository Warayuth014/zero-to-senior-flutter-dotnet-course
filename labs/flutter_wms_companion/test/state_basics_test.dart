import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/state_basics/pick_repository.dart';
import 'package:flutter_wms_companion/state_basics/pick_store.dart';
import 'package:flutter_wms_companion/state_basics/state_basics_app.dart';

import 'pick_store_test.dart' show FakePickRepository;

const _lines = [
  PickLine(id: 'L-1', palletCode: 'PAL-1001', quantity: 12),
  PickLine(id: 'L-2', palletCode: 'PAL-1002', quantity: 4),
];

String remainingText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('remaining-count'))).data!;

void main() {
  testWidgets('ระหว่างโหลดแสดงตัวหมุน แล้วเปลี่ยนเป็นรายการ', (tester) async {
    final repo = FakePickRepository();
    final gate = Completer<List<PickLine>>();
    repo.fetchGate = gate;
    final store = PickStore(repository: repo);

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pump();

    expect(find.byKey(const Key('loading-view')), findsOneWidget);

    gate.complete(_lines);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('loading-view')), findsNothing);
    expect(find.text('PAL-1001'), findsOneWidget);
    expect(remainingText(tester), 'เหลือ 2');
  });

  testWidgets('ไม่มีข้อมูลแสดงหน้าว่าง ไม่ใช่หน้าล้มเหลว', (tester) async {
    final store = PickStore(repository: FakePickRepository(lines: const []));

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-view')), findsOneWidget);
    expect(find.byKey(const Key('failed-view')), findsNothing);
  });

  testWidgets('ล้มเหลวแสดงหน้าลองใหม่ และกดแล้วโหลดซ้ำ', (tester) async {
    final repo = FakePickRepository()
      ..fetchError = const PickException('เชื่อมต่อไม่ได้');
    final store = PickStore(repository: repo);

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('failed-view')), findsOneWidget);
    expect(find.text('เชื่อมต่อไม่ได้'), findsOneWidget);

    repo.fetchError = null;
    repo.lines = _lines;
    await tester.tap(find.byKey(const Key('retry-button')));
    await tester.pumpAndSettle();

    expect(find.text('PAL-1001'), findsOneWidget);
  });

  testWidgets('กดเสร็จแล้วยอดคงเหลือลดทันที ก่อน server ตอบ', (tester) async {
    final repo = FakePickRepository(lines: _lines);
    final store = PickStore(repository: repo);

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    repo.doneGate = gate;

    await tester.tap(find.byKey(const ValueKey<String>('done-L-1')));
    await tester.pump();

    // ยังไม่ตอบ แต่หน้าจอแสดงผลไปแล้ว
    expect(remainingText(tester), 'เหลือ 1');

    gate.complete();
    await tester.pumpAndSettle();

    expect(remainingText(tester), 'เหลือ 1');
  });

  testWidgets('ล้มเหลวแล้วยอดคงเหลือกลับคืน พร้อมข้อความ', (tester) async {
    final repo = FakePickRepository(lines: _lines)
      ..doneError = const PickException('งานนี้ถูกยกเลิกแล้ว');
    final store = PickStore(repository: repo);

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('done-L-1')));
    await tester.pumpAndSettle();

    expect(remainingText(tester), 'เหลือ 2'); // ย้อนกลับแล้ว
    expect(find.byKey(const Key('inline-error')), findsOneWidget);
  });

  testWidgets('แต่ละแถวผูกกับ id ของตัวเอง ไม่ใช่ตำแหน่ง', (tester) async {
    final store = PickStore(repository: FakePickRepository(lines: _lines));

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('L-1')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('L-2')), findsOneWidget);
  });

  testWidgets('ถอดหน้าจอระหว่างโหลดแล้วไม่พัง', (tester) async {
    final repo = FakePickRepository();
    final gate = Completer<List<PickLine>>();
    repo.fetchGate = gate;
    final store = PickStore(repository: repo);

    await tester.pumpWidget(StateBasicsApp(store: store));
    await tester.pump();

    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    gate.complete(_lines);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
