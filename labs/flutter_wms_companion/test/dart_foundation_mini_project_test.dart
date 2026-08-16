import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/dart_foundation/mini_project.dart';

void main() {
  group('parseTasks', () {
    test('อ่านแถวที่ถูกต้อง และ normalize รหัสพาเลท', () {
      final report = parseTasks('''
        [{ "id": "T-01", "type": "putaway", "palletCode": " pal-1001 ",
           "quantity": 12, "location": "A-01-02" }]
      ''');

      expect(report.errors, isEmpty);
      expect(report.tasks, hasLength(1));
      expect(report.tasks.single.palletCode, 'PAL-1001');
      expect(report.tasks.single.type, TaskType.putaway);
      expect(report.tasks.single.needsLocation, isFalse);
    });

    test('quantity ที่ส่งมาเป็นข้อความยังแปลงให้ได้', () {
      final report = parseTasks(
        '[{ "id": "T-02", "type": "RETRIEVE", "palletCode": "PAL-1002", "quantity": "4" }]',
      );

      expect(report.errors, isEmpty);
      expect(report.tasks.single.quantity, 4);
    });

    test('แถวเสียถูกรายงาน แต่แถวดีต้องรอด', () {
      final report = parseTasks('''
        [
          { "id": "T-01", "type": "PUTAWAY",  "palletCode": "PAL-1001", "quantity": 1, "location": "A-01-02" },
          { "id": "T-02", "type": "TELEPORT", "palletCode": "PAL-1002", "quantity": 1 },
          { "id": "T-03", "type": "RETRIEVE", "palletCode": "PAL-1003", "quantity": 0 }
        ]
      ''');

      expect(report.tasks.map((task) => task.id), <String>['T-01']);
      expect(report.errors, hasLength(2));
      expect(report.errors.first, contains('TELEPORT'));
      expect(report.errors.last, contains('quantity'));
    });

    test('JSON เสียทั้งก้อนไม่ทำให้โปรแกรมพัง', () {
      final report = parseTasks('ไม่ใช่ JSON');

      expect(report.tasks, isEmpty);
      expect(report.errors.single, contains('JSON เสียทั้งก้อน'));
    });

    test('putaway ที่ไม่มี location ต้องถูกทำเครื่องหมายว่ายังไม่ครบ', () {
      final report = parseTasks(
        '[{ "id": "T-04", "type": "PUTAWAY", "palletCode": "PAL-1004", "quantity": 6 }]',
      );

      expect(report.tasks.single.needsLocation, isTrue);
    });
  });

  test('quantityByType รวมจำนวนตามชนิดงาน', () {
    final report = parseTasks('''
      [
        { "id": "T-01", "type": "PUTAWAY",  "palletCode": "PAL-1001", "quantity": 12, "location": "A-01-02" },
        { "id": "T-02", "type": "PUTAWAY",  "palletCode": "PAL-1002", "quantity": 6,  "location": "A-01-03" },
        { "id": "T-03", "type": "RETRIEVE", "palletCode": "PAL-1003", "quantity": 4 }
      ]
    ''');

    expect(quantityByType(report.tasks), <TaskType, int>{
      TaskType.putaway: 18,
      TaskType.retrieve: 4,
    });
  });

  test('dispatchAll นับเฉพาะใบที่ server รับ และแจ้งผลทุกใบ', () async {
    final report = parseTasks('''
      [
        { "id": "T-01", "type": "PUTAWAY",  "palletCode": "PAL-1001", "quantity": 1, "location": "A-01-02" },
        { "id": "T-02", "type": "PUTAWAY",  "palletCode": "PAL-1002", "quantity": 1 },
        { "id": "T-03", "type": "RETRIEVE", "palletCode": "PAL-1003", "quantity": 1 }
      ]
    ''');
    final seen = <String, bool>{};

    final accepted = await dispatchAll(
      report.tasks,
      send: (task) async => !task.needsLocation,
      onResult: (task, ok) => seen[task.id] = ok,
    );

    expect(accepted, 2);
    expect(seen, <String, bool>{'T-01': true, 'T-02': false, 'T-03': true});
  });
}
