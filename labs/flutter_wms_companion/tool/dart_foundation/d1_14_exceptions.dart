// ignore_for_file: avoid_print
// D1.14 Exception Handling
// รัน: dart run tool/dart_foundation/d1_14_exceptions.dart

// exception ของเราเอง: บอกได้ว่า "พังเพราะอะไร" ไม่ใช่แค่ "พัง"
class ScanException implements Exception {
  ScanException(this.message);
  final String message;
  @override
  String toString() => 'ScanException: $message';
}

class OutOfStockException implements Exception {
  OutOfStockException(this.code, this.available);
  final String code;
  final int available;
  @override
  String toString() => 'OutOfStockException: $code เหลือ $available ชิ้น';
}

int pick(String code, int requested) {
  if (code.trim().isEmpty) {
    throw ScanException('บาร์โค้ดว่าง');
  }
  const stock = <String, int>{'PAL-1001': 12, 'PAL-1002': 0};
  final available = stock[code];
  if (available == null) {
    throw ScanException('ไม่พบพาเลท $code');
  }
  if (requested > available) {
    throw OutOfStockException(code, available);
  }
  return available - requested;
}

void main() {
  print('=== จับแบบระบุชนิด: แต่ละปัญหาตอบผู้ใช้คนละแบบ ===');
  for (final input in <(String, int)>[
    ('PAL-1001', 5),
    ('PAL-1002', 3),
    ('PAL-9999', 1),
    ('', 1),
  ]) {
    print('  ${attempt(input.$1, input.$2)}');
  }

  print('\n=== finally ทำงานเสมอ ไม่ว่าจะสำเร็จหรือพัง ===');
  runWithCleanup(shouldFail: false);
  runWithCleanup(shouldFail: true);

  print('\n=== stack trace ช่วยบอกว่าพังที่บรรทัดไหน ===');
  try {
    pick('PAL-9999', 1);
  } catch (error, stackTrace) {
    print('  error = $error');
    print('  บรรทัดแรกของ stack trace:');
    print('    ${stackTrace.toString().split('\n').first.trim()}');
  }

  print('\n=== rethrow: จัดการบางส่วนแล้วส่งต่อให้ชั้นบน ===');
  try {
    logThenRethrow();
  } on ScanException catch (error) {
    print('  ชั้นบนได้รับต่อ: ${error.message}');
  }

  print('\n=== อย่ากลืน exception เงียบ ๆ ===');
  print('  แย่ : try { ... } catch (_) {}      -> ปัญหาหายไปโดยไม่มีใครรู้');
  print('  ดี  : catch แล้ว log + บอกผู้ใช้ + คืนสถานะที่ชัดเจน');
}

String attempt(String code, int requested) {
  try {
    final left = pick(code, requested);
    return 'สำเร็จ: $code เหลือ $left ชิ้น';
  } on OutOfStockException catch (error) {
    return 'ของไม่พอ: ${error.code} มีแค่ ${error.available} ชิ้น';
  } on ScanException catch (error) {
    return 'สแกนผิดพลาด: ${error.message}';
  } catch (error) {
    return 'ข้อผิดพลาดที่ไม่คาดคิด: $error';
  }
}

void runWithCleanup({required bool shouldFail}) {
  print('  เปิดรอบทำงาน (shouldFail=$shouldFail)');
  try {
    if (shouldFail) throw ScanException('จำลองความผิดพลาด');
    print('    ทำงานสำเร็จ');
  } on ScanException catch (error) {
    print('    จับได้: ${error.message}');
  } finally {
    print('    ปิดรอบทำงาน (finally ทำงานเสมอ)');
  }
}

void logThenRethrow() {
  try {
    pick('', 1);
  } on ScanException catch (error) {
    print('  บันทึก log ไว้ก่อน: ${error.message}');
    rethrow; // ส่งต่อพร้อม stack trace เดิม
  }
}
