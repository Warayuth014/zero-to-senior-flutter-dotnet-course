// ignore_for_file: avoid_print
// D1.12 Records & Pattern Matching
// รัน: dart run tool/dart_foundation/d1_12_records_patterns.dart

// record = กลุ่มค่าหลายตัวมัดรวมกัน โดยไม่ต้องประกาศ class
// เหมาะกับ "คืนค่าหลายตัว" ที่ใช้เฉพาะที่ ไม่ใช่ model ถาวรของระบบ
(String code, int quantity) parseScan(String raw) {
  final parts = raw.split('|');
  return (parts.first, int.tryParse(parts.last) ?? 0);
}

// record แบบมีชื่อ อ่านง่ายกว่าเมื่อค่ามีหลายตัว
({bool ok, String message}) validate(int quantity) {
  if (quantity <= 0) return (ok: false, message: 'จำนวนต้องมากกว่า 0');
  if (quantity > 99) return (ok: false, message: 'เกินขีดจำกัดต่อรอบ');
  return (ok: true, message: 'ผ่าน');
}

sealed class ScanEvent {}

class ScanOk extends ScanEvent {
  ScanOk(this.code, this.quantity);
  final String code;
  final int quantity;
}

class ScanFailed extends ScanEvent {
  ScanFailed(this.reason);
  final String reason;
}

class ScanIgnored extends ScanEvent {}

void main() {
  print('=== record แบบตำแหน่ง: แกะค่าออกมาเป็นตัวแปร ===');
  final (code, quantity) = parseScan('PAL-1001|12');
  print('code = $code, quantity = $quantity');
  final second = parseScan('PAL-1002|4');
  // ไม่แกะก็เข้าถึงด้วยเลขตำแหน่งได้: $1 คือค่าแรก, $2 คือค่าที่สอง
  print('เข้าถึงตรง ๆ ก็ได้: code=${second.$1}, quantity=${second.$2}');

  print('\n=== record แบบมีชื่อ ===');
  for (final input in <int>[0, 150, 12]) {
    final result = validate(input);
    print('  $input -> ok=${result.ok} (${result.message})');
  }

  print('\n=== record เท่ากันเมื่อค่าเท่ากัน (ต่างจาก class ธรรมดา) ===');
  print('(1, "A") == (1, "A") ? ${(1, 'A') == (1, 'A')}');

  print('\n=== switch expression + sealed class: ครบทุกกรณีแน่นอน ===');
  final events = <ScanEvent>[
    ScanOk('PAL-1001', 12),
    ScanFailed('อ่านบาร์โค้ดไม่ออก'),
    ScanIgnored(),
    ScanOk('PAL-1002', 1),
  ];
  for (final event in events) {
    print('  ${describe(event)}');
  }

  print('\n=== if-case: สนใจแค่รูปแบบเดียว ===');
  final raw = <String, Object?>{'code': 'PAL-1003', 'qty': 7};
  if (raw case {'code': final String c, 'qty': final int q}) {
    print('  map ตรงรูปแบบ: $c จำนวน $q');
  }

  print('\n=== guard: ใส่เงื่อนไขเพิ่มด้วย when ===');
  print('  ${classify(0)}');
  print('  ${classify(5)}');
  print('  ${classify(500)}');
}

String describe(ScanEvent event) => switch (event) {
  ScanOk(code: final c, quantity: final q) when q > 10 =>
    'สแกน $c จำนวนมาก ($q ชิ้น) ต้องยืนยันอีกครั้ง',
  ScanOk(code: final c, quantity: final q) => 'สแกน $c จำนวน $q ชิ้น',
  ScanFailed(reason: final r) => 'ล้มเหลว: $r',
  ScanIgnored() => 'ข้ามรายการนี้',
};

String classify(int quantity) => switch (quantity) {
  0 => 'ไม่มีของ',
  < 100 => 'ปกติ',
  _ => 'ต้องขออนุมัติ',
};
