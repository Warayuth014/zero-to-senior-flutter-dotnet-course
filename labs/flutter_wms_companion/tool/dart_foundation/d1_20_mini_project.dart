// ignore_for_file: avoid_print
// D1.20 Dart Mini Project
// รัน: dart run tool/dart_foundation/d1_20_mini_project.dart

import 'package:flutter_wms_companion/dart_foundation/mini_project.dart';

// ข้อมูลดิบสมมติว่ามาจาก .NET API — มีทั้งแถวดีและแถวเสียปนกัน
const rawJson = '''
[
  { "id": "T-01", "type": "PUTAWAY",  "palletCode": "pal-1001", "quantity": 12, "location": "A-01-02" },
  { "id": "T-02", "type": "RETRIEVE", "palletCode": "PAL-1002", "quantity": "4" },
  { "id": "T-03", "type": "PUTAWAY",  "palletCode": "PAL-1003", "quantity": 6 },
  { "id": "T-04", "type": "TELEPORT", "palletCode": "PAL-1004", "quantity": 1 },
  { "id": "T-05", "type": "RETRIEVE", "palletCode": "PAL-1005", "quantity": 0 },
  { "id": "T-06", "type": "RETRIEVE", "palletCode": "PAL-1006", "quantity": "มาก" }
]
''';

Future<void> main() async {
  print('=== ขั้นที่ 1: อ่านข้อมูลดิบ แถวเสียไม่ล้มทั้งชุด ===');
  final report = parseTasks(rawJson);
  print(
    '  อ่านสำเร็จ ${report.tasks.length} ใบ, มีปัญหา ${report.errors.length} แถว',
  );
  for (final error in report.errors) {
    print('    - $error');
  }

  print('\n=== ขั้นที่ 2: ดูงานที่ใช้ได้ ===');
  for (final task in report.tasks) {
    print('  $task');
  }

  print('\n=== ขั้นที่ 3: งานที่ยังขาดข้อมูล ===');
  final incomplete = report.tasks.where((task) => task.needsLocation).toList();
  print(
    incomplete.isEmpty
        ? '  ครบทุกใบ'
        : '  ต้องระบุช่องเก็บก่อน: ${incomplete.map((t) => t.id).join(', ')}',
  );

  print('\n=== ขั้นที่ 4: สรุปจำนวนตามชนิดงาน ===');
  quantityByType(report.tasks).forEach((type, quantity) {
    print('  ${type.label.padRight(8)} $quantity ชิ้น');
  });

  print('\n=== ขั้นที่ 5: ส่งงานขึ้น server (จำลอง) ===');
  final accepted = await dispatchAll(
    report.tasks,
    send: fakeSend,
    onResult: (task, ok) =>
        print('  ${task.id} -> ${ok ? 'server รับแล้ว' : 'server ปฏิเสธ'}'),
  );
  print('  ส่งสำเร็จ $accepted จาก ${report.tasks.length} ใบ');

  print('\n=== ขั้นที่ 6: ตรวจงานของคุณเอง ===');
  print('  รัน: flutter test test/dart_foundation_mini_project_test.dart');
}

// จำลองเครือข่าย: ใช้เวลาเล็กน้อย และปฏิเสธงานที่ยังไม่ระบุช่องเก็บ
Future<bool> fakeSend(WarehouseTask task) async {
  await Future<void>.delayed(const Duration(milliseconds: 80));
  return !task.needsLocation;
}
