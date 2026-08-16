// ignore_for_file: avoid_print
// D1.15 Future / async / await
// รัน: dart run tool/dart_foundation/d1_15_async.dart

import 'dart:async';

// จำลองการเรียก API: ใช้เวลา แล้วค่อยได้คำตอบ
Future<String> fetchPallet(String code, {int ms = 300}) async {
  await Future<void>.delayed(Duration(milliseconds: ms));
  if (code == 'PAL-BROKEN') {
    throw StateError('server ตอบ 500 สำหรับ $code');
  }
  return '$code (โหลดใน ${ms}ms)';
}

Future<void> main() async {
  final clock = Stopwatch()..start();
  void mark(String label) =>
      print('  [${clock.elapsedMilliseconds.toString().padLeft(4)}ms] $label');

  print('=== Future คือ "ใบรับของ" ยังไม่ใช่ตัวข้อมูล ===');
  final receipt = fetchPallet('PAL-1001');
  print('  ชนิดที่ได้ทันที = ${receipt.runtimeType}');
  mark('ยังไม่ await — โค้ดบรรทัดถัดไปทำงานต่อได้');
  mark('ได้ข้อมูลแล้ว: ${await receipt}');

  print('\n=== เรียงทีละตัว (sequential): ช้ากว่าเพราะรอต่อคิว ===');
  clock.reset();
  final a = await fetchPallet('PAL-A');
  final b = await fetchPallet('PAL-B');
  mark('$a, $b');

  print('\n=== ยิงพร้อมกัน (concurrent) ด้วย Future.wait ===');
  clock.reset();
  final both = await Future.wait<String>([
    fetchPallet('PAL-A'),
    fetchPallet('PAL-B'),
  ]);
  mark(both.join(' + '));

  print('\n=== จับ error ของงาน async ด้วย try/catch ปกติ ===');
  try {
    await fetchPallet('PAL-BROKEN');
  } on StateError catch (error) {
    print('  จับได้: ${error.message}');
  }

  print('\n=== timeout: ไม่รอตลอดกาล ===');
  try {
    await fetchPallet(
      'PAL-SLOW',
      ms: 2000,
    ).timeout(const Duration(milliseconds: 400));
  } on TimeoutException {
    print('  เกินเวลา 400ms -> บอกผู้ใช้ว่าเครือข่ายช้า');
  }

  print('\n=== กันกดซ้ำ: ถ้ายังทำงานอยู่ ไม่รับคำสั่งใหม่ ===');
  final loader = PalletLoader();
  await Future.wait<void>([
    loader.load('PAL-1001'),
    loader.load('PAL-1002'), // ถูกปฏิเสธเพราะตัวแรกยังไม่เสร็จ
  ]);

  print('\n=== ลำดับที่ต้องจำ ===');
  print('  โค้ดก่อน await ทำงานทันที');
  print('  โค้ดหลัง await ทำงานเมื่องานเสร็จแล้วเท่านั้น');
}

class PalletLoader {
  bool _loading = false;

  Future<void> load(String code) async {
    if (_loading) {
      print('  ปฏิเสธ $code เพราะกำลังโหลดอยู่');
      return;
    }
    _loading = true;
    try {
      final result = await fetchPallet(code);
      print('  โหลดสำเร็จ: $result');
    } finally {
      _loading = false; // ปลดล็อกเสมอ แม้จะพัง
    }
  }
}
