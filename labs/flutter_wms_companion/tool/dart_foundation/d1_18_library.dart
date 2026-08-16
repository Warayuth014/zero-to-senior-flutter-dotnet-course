// ignore_for_file: avoid_print
// D1.18 Library / Import / Privacy
// รัน: dart run tool/dart_foundation/d1_18_library.dart

// 1) import ไฟล์ในโปรเจกต์ด้วย path สัมพัทธ์
//    เรา import แค่ warehouse.dart ไฟล์เดียว เพราะมันเปิดของให้ครบแล้ว
import 'warehouse/warehouse.dart';

// 2) import แบบตั้งชื่อ (as) กันชื่อชนกัน และอ่านออกว่าของมาจากไหน
import 'dart:math' as math;

// 3) import เฉพาะที่ใช้ ด้วย show / hide
import 'dart:convert' show jsonEncode;

void main() {
  print('=== ใช้ของจาก library อื่น ===');
  final pallet = Pallet.parse('  pal-1001  ');
  final location = StorageLocation.parse('A-01-02');
  print('  $pallet เก็บที่ $location');

  print('\n=== ของที่ขึ้นต้นด้วย _ ถูกซ่อนไว้ ===');
  // Pallet._('X', 0);   // error: constructor private
  // _normalize('abc');  // error: ไฟล์นี้มองไม่เห็นเลย
  print('  เข้าถึงได้ทางเดียวคือ Pallet.parse() ซึ่งตรวจข้อมูลให้เสมอ');
  try {
    Pallet.parse('ABC');
  } on FormatException catch (error) {
    print('  ถูกปฏิเสธ: ${error.message}');
  }

  print('\n=== import as: รู้ทันทีว่า max มาจากไหน ===');
  print('  math.max(3, 9) = ${math.max(3, 9)}');

  print('\n=== import show: ดึงมาเฉพาะที่ใช้ ===');
  print('  ${jsonEncode({'code': pallet.code, 'location': '$location'})}');

  print('\n=== ทิศทางการพึ่งพา ===');
  print('  warehouse/ ไม่รู้จักไฟล์นี้ — พึ่งพาทางเดียวเท่านั้น');
  print(
    '  ถ้าสองไฟล์ import กันไปมา แปลว่าแบ่งหน้าที่ผิด ต้องแยกส่วนกลางออกมา',
  );
}
