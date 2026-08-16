// ignore_for_file: avoid_print
// D1.4 Functions & Parameters
// รัน: dart run tool/dart_foundation/d1_04_functions.dart

// 1) parameter แบบตำแหน่ง (positional) — ลำดับสำคัญ
String labelOf(String code, int quantity) => '$code x $quantity';

// 2) parameter แบบมีชื่อ (named) — เรียกแล้วอ่านรู้เรื่อง
//    required = ต้องส่ง, ไม่ใส่ required ต้องมีค่า default หรือเป็น nullable
String pickLine({
  required String code,
  required String location,
  int quantity = 1,
  String? note,
}) {
  final suffix = note == null ? '' : ' ($note)';
  return 'หยิบ $code จำนวน $quantity จาก $location$suffix';
}

// 3) parameter แบบตำแหน่งที่ใส่หรือไม่ใส่ก็ได้ ใช้ [ ]
String shortCode(String code, [int keep = 3]) =>
    code.length <= keep ? code : code.substring(0, keep);

// 4) ฟังก์ชันที่ไม่คืนค่า ใช้ void
void report(String message) => print('  [report] $message');

void main() {
  print('=== positional: ลำดับผิด = ความหมายผิด ===');
  print(labelOf('PAL-1001', 12));

  print('\n=== named: อ่านที่จุดเรียกก็เข้าใจ ===');
  print(pickLine(code: 'PAL-1001', location: 'A-01-02'));
  print(pickLine(code: 'PAL-1002', location: 'B-03-01', quantity: 5));
  print(
    pickLine(
      code: 'PAL-1003',
      location: 'C-02-04',
      quantity: 2,
      note: 'ของแตกง่าย',
    ),
  );

  print('\n=== optional positional ===');
  print(shortCode('PAL-1001'));
  print(shortCode('PAL-1001', 7));

  print('\n=== void ใช้ทำงาน ไม่ได้เอาค่ากลับ ===');
  report('เริ่มรอบตรวจนับ');

  print('\n=== ฟังก์ชันเป็นค่าได้: ส่งชื่อฟังก์ชันโดยไม่ใส่วงเล็บ ===');
  final printer = report; // ส่งตัวฟังก์ชัน
  printer('ส่งฟังก์ชันไปทำงานทีหลัง');
  // report('...') คือ "เรียกทันที" ส่วน report คือ "ตัวฟังก์ชันเอง"

  print('\n=== ฟังก์ชันซ้อนและ closure ===');
  final addTax = makeAdder(7);
  print('100 + ภาษี 7 = ${addTax(100)}');
  print('250 + ภาษี 7 = ${addTax(250)}');
}

// makeAdder คืนฟังก์ชันที่ "จำ" ค่า amount เอาไว้ เรียกว่า closure
int Function(int) makeAdder(int amount) {
  return (int value) => value + amount;
}
