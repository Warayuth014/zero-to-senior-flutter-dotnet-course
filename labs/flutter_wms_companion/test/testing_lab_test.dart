import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/json_basics/json_read.dart';
import 'package:flutter_wms_companion/json_basics/task_dto.dart';
import 'package:flutter_wms_companion/testing_lab/counter_board.dart';
import 'package:flutter_wms_companion/testing_lab/pallet_list.dart';
import 'package:flutter_wms_companion/testing_lab/rebuild_counter.dart';

/// อ่านไฟล์ตัวอย่างที่เก็บไว้ใน test/fixtures
///
/// เก็บเป็นไฟล์แยก ไม่ใช่สตริงในเทสต์ เพราะเป็น**สำเนาของสิ่งที่เซิร์ฟเวอร์
/// ส่งมาจริง** — คัดลอกจาก log ได้ตรง ๆ และอัปเดตได้โดยไม่ต้องแก้โค้ด (14.5)
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('เทสต์สัญญากับเซิร์ฟเวอร์', () {
    test('ไฟล์ตัวอย่างที่เก็บไว้ ต้องอ่านได้ด้วยโมเดลปัจจุบัน', () {
      final json = loadFixture('tasks_page.json');
      final items = requireList(json, 'items');

      final tasks = [
        for (var i = 0; i < items.length; i++)
          TaskDto.fromJson(requireMap(items[i], 'items[$i]')),
      ];

      expect(tasks, isNotEmpty);
      for (final task in tasks) {
        expect(task.id.trim(), isNotEmpty);
        expect(task.quantity, greaterThanOrEqualTo(0));
      }
    });

    test('รูปแบบ PascalCase ที่ระบบเก่าส่งมา ต้องอ่านได้ด้วยตัวอ่านชุดเดียวกัน', () {
      // ไฟล์นี้มาจากระบบเก่าที่ส่งชื่อฟิลด์เป็น PascalCase ทั้งหมด
      // โค้ดที่อ่านเป็นชุดเดียวกับที่อ่าน camelCase ไม่มีสาขาแยก (6.6)
      final json = loadFixture('tasks_page_pascal.json');
      final items = requireList(json, 'items');

      final tasks = [
        for (var i = 0; i < items.length; i++)
          TaskDto.fromJson(requireMap(items[i], 'items[$i]')),
      ];

      expect(tasks.single.id, 'T-101');
      expect(tasks.single.quantity, 5);
      expect(tasks.single.palletCode, 'PAL-0201');
    });

    test('ฟิลด์ที่หายไปจากไฟล์ตัวอย่าง ต้องทำให้เทสต์ล้ม ไม่ใช่ผ่านเงียบ ๆ', () {
      // จำลองว่าเซิร์ฟเวอร์รุ่นใหม่เลิกส่ง quantity
      final json = loadFixture('tasks_page.json');
      final items = requireList(json, 'items');
      final broken = Map<String, dynamic>.from(requireMap(items.first, 'x'))
        ..remove('quantity')
        ..remove('Quantity');

      expect(
        () => TaskDto.fromJson(broken),
        throwsA(isA<ContractException>()),
        reason: 'สัญญาที่หายไปต้องดัง ไม่ใช่กลายเป็นศูนย์เงียบ ๆ',
      );
    });
  });

  group('นับการวาดใหม่', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    testWidgets('วาดครั้งแรก ทุกส่วนถูกวาดหนึ่งครั้ง', (tester) async {
      final counter = RebuildCounter();
      final state = BoardState();

      await tester.pumpWidget(
        wrap(WideRebuildBoard(state: state, counter: counter)),
      );

      expect(counter.countOf('header'), 1);
      expect(counter.countOf('counter'), 1);
      expect(counter.countOf('expensive'), 1);
    });

    testWidgets('รุ่นที่ครอบทั้งจอ วาดใหม่ทุกส่วนแม้ค่าที่ใช้ไม่เปลี่ยน', (
      tester,
    ) async {
      final counter = RebuildCounter();
      final state = BoardState();
      await tester.pumpWidget(
        wrap(WideRebuildBoard(state: state, counter: counter)),
      );

      state.scan();
      await tester.pump();

      // ชื่อผู้ปฏิบัติงานไม่ได้เปลี่ยน แต่ยังถูกวาดใหม่
      expect(counter.countOf('header'), 2);
      expect(counter.countOf('counter'), 2);
      // และส่วนที่แพงก็ถูกวาดใหม่ด้วย ทั้งที่ไม่ได้ใช้ค่าอะไรเลย
      expect(counter.countOf('expensive'), 2);
    });

    testWidgets('รุ่นที่ครอบแคบ ส่วนที่แพงไม่ถูกวาดใหม่', (tester) async {
      final counter = RebuildCounter();
      final state = BoardState();
      await tester.pumpWidget(
        wrap(NarrowRebuildBoard(state: state, counter: counter)),
      );

      state.scan();
      await tester.pump();

      expect(counter.countOf('counter'), 2);
      expect(counter.countOf('expensive'), 1, reason: 'ไม่ควรถูกวาดใหม่เลย');
    });

    testWidgets('สแกนสิบครั้ง ส่วนที่แพงยังวาดครั้งเดียว', (tester) async {
      final counter = RebuildCounter();
      final state = BoardState();
      await tester.pumpWidget(
        wrap(NarrowRebuildBoard(state: state, counter: counter)),
      );

      for (var i = 0; i < 10; i++) {
        state.scan();
        await tester.pump();
      }

      expect(counter.countOf('counter'), 11);
      expect(counter.countOf('expensive'), 1);
    });

    testWidgets('ตั้งค่าเดิมซ้ำ ต้องไม่วาดใหม่เลย', (tester) async {
      final counter = RebuildCounter();
      final state = BoardState();
      await tester.pumpWidget(
        wrap(NarrowRebuildBoard(state: state, counter: counter)),
      );
      final before = counter.snapshot;

      // ChangeNotifier ที่ไม่ประกาศเมื่อค่าไม่เปลี่ยน (11.7)
      state.changeOperator('somchai');
      await tester.pump();

      expect(counter.snapshot, before);
    });
  });

  group('ลิสต์ยาว', () {
    Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

    final codes = [for (var i = 0; i < 500; i++) 'PLT-${i.toString().padLeft(4, '0')}'];

    testWidgets('Column สร้างทุกแถวแม้เห็นไม่ถึงสิบ', (tester) async {
      final counter = RebuildCounter();
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(EagerPalletList(codes: codes, counter: counter)),
      );

      expect(counter.countOf('row'), 500);
    });

    testWidgets('ListView.builder สร้างเฉพาะที่ใกล้จะเห็น', (tester) async {
      final counter = RebuildCounter();
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(LazyPalletList(codes: codes, counter: counter)),
      );

      // จอสูง 600 แถวละ 56 เห็นได้ราว 11 แถว บวกที่เตรียมไว้ล่วงหน้า
      expect(counter.countOf('row'), lessThan(40));
      expect(counter.countOf('row'), greaterThan(5));
    });

    testWidgets('เลื่อนแล้วสร้างแถวใหม่เพิ่ม แต่ยังไม่ครบทั้งหมด', (
      tester,
    ) async {
      final counter = RebuildCounter();
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        wrap(LazyPalletList(codes: codes, counter: counter)),
      );
      final beforeScroll = counter.countOf('row');

      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pump();

      expect(counter.countOf('row'), greaterThan(beforeScroll));
      expect(counter.countOf('row'), lessThan(200));
    });
  });
}
