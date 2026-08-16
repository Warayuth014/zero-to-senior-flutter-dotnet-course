// D1.18 — ไฟล์นี้คือหนึ่ง library
// อะไรที่ขึ้นต้นด้วย _ จะมองไม่เห็นจากไฟล์อื่น แม้จะ import แล้วก็ตาม

/// รหัสพาเลทที่ตรวจรูปแบบแล้ว
class Pallet {
  Pallet._(this.code, this.quantity);

  /// ทางเข้าเดียวที่ไฟล์อื่นใช้ได้ — บังคับให้ผ่านการตรวจเสมอ
  factory Pallet.parse(String raw) {
    final normalized = _normalize(raw);
    if (!_isValidCode(normalized)) {
      throw FormatException('รหัสพาเลทไม่ถูกรูปแบบ: $raw');
    }
    return Pallet._(normalized, 0);
  }

  final String code;
  final int quantity;

  Pallet copyWith({int? quantity}) => Pallet._(code, quantity ?? this.quantity);

  @override
  String toString() => '$code ($quantity ชิ้น)';
}

// ฟังก์ชัน private: เป็นรายละเอียดภายในของ library นี้
String _normalize(String raw) => raw.trim().toUpperCase();

bool _isValidCode(String code) => code.startsWith('PAL-') && code.length == 8;
