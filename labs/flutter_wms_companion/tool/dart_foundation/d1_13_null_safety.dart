// ignore_for_file: avoid_print
// D1.13 Null Safety
// รัน: dart run tool/dart_foundation/d1_13_null_safety.dart

class Pallet {
  Pallet({required this.code, this.location, this.note});

  final String code;
  final String? location; // null = ยังไม่ถูกจัดเก็บ (เป็นสถานะจริง)
  final String? note;
}

class ScanBox {
  String? code; // field ที่เปลี่ยนได้ -> Dart promote ให้ไม่ได้
}

void main() {
  print('=== String กับ String? ต่างกันที่ "ว่างได้ไหม" ===');
  const String must = 'PAL-1001'; // ห้ามเป็น null
  const String? maybe = null; // เป็น null ได้
  print('must = $must, maybe = $maybe');

  print('\n=== ?? ให้ค่าสำรองเมื่อเป็น null ===');
  final pallets = <Pallet>[
    Pallet(code: 'PAL-1001', location: 'A-01-02'),
    Pallet(code: 'PAL-1002'),
  ];
  for (final pallet in pallets) {
    print('  ${pallet.code} อยู่ที่ ${pallet.location ?? 'ยังไม่จัดเก็บ'}');
  }

  print('\n=== ?. เรียกต่อเมื่อไม่ null ===');
  for (final pallet in pallets) {
    print('  ${pallet.code} ความยาวช่องเก็บ = ${pallet.location?.length}');
  }

  print('\n=== ??= ใส่ค่าเมื่อยังว่างเท่านั้น ===');
  String? note = pallets.first.note;
  note ??= 'ไม่มีหมายเหตุ';
  print('  note = $note');

  print('\n=== type promotion: ผ่าน if แล้ว Dart รู้ว่าไม่ null ===');
  final target = pallets.first;
  final location = target.location;
  if (location != null) {
    print('  ตัวพิมพ์ใหญ่: ${location.toUpperCase()}'); // ไม่ต้องใส่ ! เลย
  }

  print('\n=== ทำไมบางครั้ง promote ไม่ได้ ===');
  final box = ScanBox()..code = 'PAL-1003';
  if (box.code != null) {
    // box.code.toUpperCase();  // error: field แบบเปลี่ยนได้ อาจถูกแก้ระหว่างทาง
    final local = box.code!; // ดึงลงตัวแปร local ก่อน แล้วค่อยใช้
    print('  ผ่าน local variable: ${local.toUpperCase()}');
  }

  print('\n=== ! คือคำสัญญา ถ้าผิดสัญญาโปรแกรมพังทันที ===');
  String? empty;
  try {
    print(empty!.length);
  } on TypeError {
    print('  พังเพราะใช้ ! กับค่าที่เป็น null จริง ๆ');
  }

  print('\n=== อย่าใช้ค่าวิเศษแทน null ===');
  print('  แย่ : quantity = -1 แปลว่า "ไม่รู้"  -> คนอ่านต้องเดา');
  print('  ดี  : int? quantity = null           -> ตรวจก่อนใช้เสมอ');
}
