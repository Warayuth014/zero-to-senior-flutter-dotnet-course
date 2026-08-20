/// ตัวอ่านค่าจาก JSON ที่ใช้ร่วมกันทั้งแอป
///
/// ทุก model ต้องอ่านผ่านไฟล์นี้ ไม่เขียน `json['x'] as String` เอง
/// เพราะกฎการแปลงค่าต้องเหมือนกันทุกที่ และข้อความผิดพลาดต้องบอกตำแหน่งได้
library;

/// ข้อมูลจากเซิร์ฟเวอร์ไม่ตรงกับที่ตกลงกันไว้
///
/// ต่างจาก FormatException ตรงที่พก [path] มาด้วย ทำให้รู้ว่าพังตรงไหน
/// ในก้อน JSON ที่อาจซ้อนกันหลายชั้น
class ContractException implements Exception {
  const ContractException(this.path, this.message);

  /// ตำแหน่งในก้อน JSON เช่น `items[3].quantity`
  final String path;
  final String message;

  @override
  String toString() => 'ContractException ที่ $path: $message';
}

/// ค่าที่ใช้แทน "ไม่มีคีย์นี้เลย" ซึ่งต่างจาก "มีคีย์แต่ค่าเป็น null"
const Object _absent = Object();

String _at(String path, String key) => path.isEmpty ? key : '$path.$key';

/// อ่านค่าดิบ โดยลองทั้ง camelCase และ PascalCase
///
/// ASP.NET รุ่นใหม่ส่ง camelCase แต่ระบบเก่าส่ง PascalCase
/// การรองรับทั้งสองแบบไว้ที่เดียวทำให้ model ทุกตัวไม่ต้องรู้เรื่องนี้
Object? _raw(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  final pascal = key[0].toUpperCase() + key.substring(1);
  if (json.containsKey(pascal)) return json[pascal];
  return _absent;
}

/// คีย์นี้มีอยู่จริงไหม (ไม่สนว่าค่าเป็น null หรือไม่)
bool hasKey(Map<String, dynamic> json, String key) =>
    !identical(_raw(json, key), _absent);

Object? _require(Map<String, dynamic> json, String key, String path) {
  final value = _raw(json, key);
  if (identical(value, _absent)) {
    throw ContractException(_at(path, key), 'ไม่มีคีย์นี้ในข้อมูลที่ได้รับ');
  }
  if (value == null) {
    throw ContractException(_at(path, key), 'ค่าต้องไม่เป็น null');
  }
  return value;
}

// ---------------------------------------------------------------- ตัวครอบ

/// ตรวจว่าเป็น object จริงก่อนอ่านข้างใน
Map<String, dynamic> requireMap(Object? value, String path) {
  if (value is Map<String, dynamic>) return value;
  throw ContractException(path, 'ต้องเป็น object แต่ได้ ${value.runtimeType}');
}

/// ตรวจว่าเป็น array จริงก่อนวนอ่าน
List<Object?> requireList(Map<String, dynamic> json, String key, {
  String path = '',
}) {
  final value = _require(json, key, path);
  if (value is List) return value;
  throw ContractException(
    _at(path, key),
    'ต้องเป็น array แต่ได้ ${value.runtimeType}',
  );
}

// ---------------------------------------------------------------- ข้อความ

String requireString(Map<String, dynamic> json, String key, {String path = ''}) {
  final value = _require(json, key, path);
  if (value is! String) {
    throw ContractException(
      _at(path, key),
      'ต้องเป็นข้อความ แต่ได้ ${value.runtimeType}',
    );
  }
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ContractException(_at(path, key), 'ต้องไม่เป็นข้อความว่าง');
  }
  return trimmed;
}

/// อ่านข้อความที่เซิร์ฟเวอร์อนุญาตให้ไม่มีได้
///
/// ทั้งไม่มีคีย์ ค่าเป็น null และข้อความว่าง ถือเป็น null เหมือนกัน
/// เพราะทั้งสามหมายถึง "ไม่มีข้อมูล" ในความหมายของหน้าจอ
String? readString(Map<String, dynamic> json, String key, {String path = ''}) {
  final value = _raw(json, key);
  if (identical(value, _absent) || value == null) return null;
  if (value is! String) {
    throw ContractException(
      _at(path, key),
      'ต้องเป็นข้อความ แต่ได้ ${value.runtimeType}',
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

// ---------------------------------------------------------------- ตัวเลข

/// JSON ไม่แยก int กับ double — 5 กับ 5.0 เป็นเลขเดียวกันในสายตา JSON
/// และระบบเก่าบางตัวส่งตัวเลขมาเป็นข้อความ
double requireDouble(Map<String, dynamic> json, String key, {String path = ''}) {
  final value = _require(json, key, path);
  final parsed = _toDouble(value);
  if (parsed == null) {
    throw ContractException(
      _at(path, key),
      'ต้องเป็นตัวเลข แต่ได้ ${value.runtimeType} ($value)',
    );
  }
  return parsed;
}

double? _toDouble(Object? value) => switch (value) {
  num n => n.toDouble(),
  String s => double.tryParse(s.trim()),
  _ => null,
};

/// จำนวนชิ้นต้องเป็นจำนวนเต็ม
///
/// รับ 5 และ 5.0 เพราะเป็นจำนวนเต็มเท่ากัน แต่ปฏิเสธ 1.9
/// การปัดเศษเงียบ ๆ ในงานคลังคือของหายหรือของเกิน
int requireInt(Map<String, dynamic> json, String key, {String path = ''}) {
  final value = _require(json, key, path);
  final parsed = _toDouble(value);
  if (parsed == null) {
    throw ContractException(
      _at(path, key),
      'ต้องเป็นตัวเลข แต่ได้ ${value.runtimeType} ($value)',
    );
  }
  if (parsed != parsed.roundToDouble()) {
    throw ContractException(
      _at(path, key),
      'ต้องเป็นจำนวนเต็ม แต่ได้ $value',
    );
  }
  return parsed.toInt();
}

// ---------------------------------------------------------------- เวลา

/// เวลาต้องมี Z หรือ offset เสมอ
///
/// "2026-08-15T10:00:00" ตีความไม่ได้ว่าเป็นเวลาที่ไหน — คลังที่อยู่คนละ
/// เขตเวลาจะอ่านได้คนละความหมาย จึงต้องปฏิเสธตั้งแต่ขอบ
final RegExp _hasZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

DateTime requireUtcTime(Map<String, dynamic> json, String key, {
  String path = '',
}) {
  final raw = requireString(json, key, path: path);
  if (!_hasZone.hasMatch(raw)) {
    throw ContractException(
      _at(path, key),
      'เวลาต้องระบุเขตเวลาด้วย Z หรือ offset แต่ได้ "$raw"',
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    throw ContractException(_at(path, key), 'รูปแบบเวลาไม่ถูกต้อง: "$raw"');
  }
  return parsed.toUtc();
}
