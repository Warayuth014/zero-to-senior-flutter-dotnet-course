// ignore_for_file: avoid_print
// D1.19 JSON / dynamic / Cast
// รัน: dart run tool/dart_foundation/d1_19_json.dart

import 'dart:convert';

// นี่คือรูปแบบที่ .NET API ส่งกลับมาจริง ๆ (ตัวอย่างที่ถอดรูปให้ง่ายลง)
const rawResponse = '''
{
  "success": true,
  "message": "ok",
  "data": [
    { "palletCode": "PAL-1001", "quantity": 12, "location": "A-01-02", "receivedAt": "2026-08-16T09:30:00" },
    { "palletCode": "PAL-1002", "quantity": "4", "location": null, "receivedAt": null }
  ]
}
''';

class Pallet {
  Pallet({
    required this.palletCode,
    required this.quantity,
    this.location,
    this.receivedAt,
  });

  // จุดเดียวในระบบที่ยอมแตะ dynamic — หลังจากนี้ทุกอย่างมีชนิดชัดเจน
  factory Pallet.fromJson(Map<String, dynamic> json) {
    return Pallet(
      palletCode: _asString(json['palletCode']),
      quantity: _asInt(json['quantity']),
      location: json['location'] as String?,
      receivedAt: _asDate(json['receivedAt']),
    );
  }

  final String palletCode;
  final int quantity;
  final String? location;
  final DateTime? receivedAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'palletCode': palletCode,
    'quantity': quantity,
    'location': location,
    'receivedAt': receivedAt?.toIso8601String(),
  };

  @override
  String toString() =>
      '$palletCode x$quantity @ ${location ?? '-'} (${receivedAt?.year ?? '-'})';
}

// ตัวช่วยที่ "ทนความต่างเล็กน้อย" แต่ไม่กลืนข้อมูลเสีย
String _asString(Object? value) {
  if (value is String) return value;
  throw FormatException('คาดว่าเป็นข้อความ แต่ได้ $value');
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException('แปลงเป็นจำนวนเต็มไม่ได้: $value');
}

DateTime? _asDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;

void main() {
  print('=== 1) decode: ข้อความ -> โครงสร้าง dynamic ===');
  final decoded = jsonDecode(rawResponse) as Map<String, dynamic>;
  print('  ชนิดที่ได้ = ${decoded.runtimeType}');
  print('  success   = ${decoded['success']}');

  print('\n=== 2) แปลงเป็น model ทันที ห้ามปล่อย dynamic ไหลเข้าหน้าจอ ===');
  final rows = decoded['data'] as List<dynamic>;
  final pallets = rows
      .map((row) => Pallet.fromJson(row as Map<String, dynamic>))
      .toList();
  for (final pallet in pallets) {
    print('  $pallet');
  }

  print('\n=== 3) quantity ส่งมาเป็น "4" (ข้อความ) ก็ยังรอด ===');
  print('  ผลรวม = ${pallets.fold<int>(0, (sum, p) => sum + p.quantity)} ชิ้น');

  print('\n=== 4) ข้อมูลผิดรูป ต้องพังที่ parser ไม่ใช่ที่หน้าจอ ===');
  try {
    Pallet.fromJson(<String, dynamic>{
      'palletCode': 'PAL-9',
      'quantity': 'มาก',
    });
  } on FormatException catch (error) {
    print('  จับได้ตั้งแต่ชั้น parser: ${error.message}');
  }

  print('\n=== 5) ส่งกลับขึ้น API ===');
  print('  ${jsonEncode(pallets.first.toJson())}');

  print('\n=== 6) ชื่อ key ต้องตรงกับที่ .NET ส่งจริง ===');
  print('  .NET มักส่ง camelCase: palletCode, quantity');
  print('  พิมพ์ผิดหนึ่งตัว = ได้ null เงียบ ๆ ไม่มี error');
  final typo = <String, dynamic>{'PalletCode': 'PAL-1', 'quantity': 1};
  print('  typo["palletCode"] = ${typo['palletCode']}  <- null');
}
