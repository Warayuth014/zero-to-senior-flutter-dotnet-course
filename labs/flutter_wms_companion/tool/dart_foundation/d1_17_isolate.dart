// ignore_for_file: avoid_print
// D1.17 Isolate
// รัน: dart run tool/dart_foundation/d1_17_isolate.dart

import 'dart:isolate';

// งานหนักแบบ CPU-bound: คำนวณล้วน ไม่ได้รอเครือข่าย
// await ช่วยไม่ได้ เพราะไม่มีอะไรให้ "รอ" — มันกินเวลา CPU จริง ๆ
int heavySum(int rounds) {
  var total = 0;
  for (var i = 0; i < rounds; i++) {
    total = (total + i * i) % 1000000007;
  }
  return total;
}

Future<void> main() async {
  const rounds = 250000000; // ใหญ่พอให้เห็นว่า "ค้าง" จริง ๆ

  print('=== ทำบน isolate หลัก: ทุกอย่างค้างระหว่างคำนวณ ===');
  final blocking = Stopwatch()..start();
  final blockingResult = heavySum(rounds);
  blocking.stop();
  print(
    '  ผลลัพธ์ = $blockingResult ใช้เวลา ${blocking.elapsedMilliseconds}ms',
  );
  print('  ระหว่างนี้ ถ้าเป็นแอป Flutter หน้าจอจะกระตุกหรือค้าง');

  print('\n=== ย้ายไป isolate อื่นด้วย Isolate.run ===');
  final offloaded = Stopwatch()..start();
  final future = Isolate.run(() => heavySum(rounds));
  print('  isolate หลักยังว่าง ทำงานอื่นต่อได้ทันที');
  for (var tick = 1; tick <= 3; tick++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    print('  ...ยังตอบสนอง tick $tick');
  }
  final offloadedResult = await future;
  offloaded.stop();
  print(
    '  ผลลัพธ์ = $offloadedResult ใช้เวลา ${offloaded.elapsedMilliseconds}ms',
  );

  print('\n=== isolate ไม่แชร์หน่วยความจำกัน ===');
  var counter = 0;
  await Isolate.run(() {
    // ตัวแปร counter ถูก "คัดลอก" ไป ไม่ใช่ตัวเดียวกัน
    var localCopy = 0;
    localCopy += 100;
    return localCopy;
  }).then((value) => print('  ค่าที่ isolate คำนวณได้ = $value'));
  print('  counter ฝั่งนี้ยังเป็น $counter (ไม่ถูกแก้ข้ามฝั่ง)');

  print('\n=== ส่งข้อมูลข้าม isolate ต้องส่งเป็นข้อความ/ค่าธรรมดา ===');
  final parsed = await Isolate.run(() {
    final rows = List<String>.generate(5, (i) => 'PAL-${1000 + i}|${i * 3}');
    return rows.map((row) => row.split('|').first).toList();
  });
  print('  โค้ดที่แยกไปแกะข้อมูลคืนมา: $parsed');

  print('\n=== ใช้เมื่อไหร่ ===');
  print('  รอเครือข่าย/ไฟล์ -> ใช้ async/await ก็พอ');
  print('  คำนวณหนัก เช่น แกะ JSON ก้อนใหญ่, ประมวลผลภาพ -> ใช้ isolate');
}
