// ignore_for_file: avoid_print
// D1.7 Encapsulation & Getter
// รัน: dart run tool/dart_foundation/d1_07_encapsulation.dart

class ScanSession {
  ScanSession({required this.operator});

  final String operator;

  // ขึ้นต้นด้วย _ = private ต่อไฟล์นี้ (library) คนอื่นแก้ตรง ๆ ไม่ได้
  final List<String> _scanned = <String>[];
  bool _closed = false;

  // getter: อ่านได้อย่างเดียว หน้าตาเหมือน field แต่คำนวณให้
  int get count => _scanned.length;

  bool get isEmpty => _scanned.isEmpty;

  bool get closed => _closed;

  // คืนสำเนาที่แก้ไม่ได้ ป้องกันคนนอกแอบ add เข้ามา
  List<String> get scanned => List.unmodifiable(_scanned);

  // setter: ควบคุมเงื่อนไขก่อนยอมให้เปลี่ยนค่า
  set closed(bool value) {
    if (_closed && !value) {
      throw StateError('ปิดรอบไปแล้ว เปิดซ้ำไม่ได้');
    }
    _closed = value;
  }

  void add(String code) {
    if (_closed) {
      throw StateError('รอบนี้ปิดแล้ว สแกนเพิ่มไม่ได้');
    }
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty || _scanned.contains(normalized)) return;
    _scanned.add(normalized);
  }
}

// extension: เพิ่ม "มุมมอง" ให้ชนิดที่เราไม่ได้เป็นเจ้าของ โดยไม่แก้ต้นฉบับ
extension ScanSessionSummary on ScanSession {
  String get summary => '$operator สแกนแล้ว $count รายการ';
}

void main() {
  final session = ScanSession(operator: 'สมชาย');

  print('=== เพิ่มผ่าน method เท่านั้น จึงกรองข้อมูลได้ ===');
  session.add('pal-1001');
  session.add('  PAL-1001  '); // ซ้ำหลัง normalize -> ถูกตัดทิ้ง
  session.add('PAL-1002');
  session.add('   '); // ว่าง -> ถูกตัดทิ้ง
  print('scanned = ${session.scanned}');
  print('count   = ${session.count}');
  print('isEmpty = ${session.isEmpty}');

  print('\n=== list ที่คืนออกไปแก้ไม่ได้ ===');
  try {
    session.scanned.add('PAL-9999');
  } on UnsupportedError {
    print('ถูกปฏิเสธ: คนนอกเพิ่มข้อมูลเองไม่ได้');
  }

  print('\n=== setter บังคับกฎ ===');
  session.closed = true;
  try {
    session.add('PAL-1003');
  } on StateError catch (error) {
    print('ถูกปฏิเสธ: ${error.message}');
  }

  print('\n=== extension ===');
  print(session.summary);
}
