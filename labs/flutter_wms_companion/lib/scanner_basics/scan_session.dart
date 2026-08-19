/// Lab ของ Part 3 — ส่วนตรรกะล้วน ไม่มี Flutter ปนเลย
///
/// แยกออกมาเพื่อให้เขียนเทสต์ได้โดยไม่ต้องประกอบหน้าจอ
/// ตามหลักเดียวกับ D1.20: ตรรกะที่ไม่ผูกกับ UI คือตรรกะที่ทดสอบได้
library;

/// ผลของการรับบาร์โค้ดหนึ่งครั้ง
///
/// ใช้ enum แทน bool หลายตัว เพื่อไม่ให้เกิดสถานะที่ขัดแย้งกันเอง (D1.10)
enum ScanOutcome {
  accepted('รับเข้าแล้ว'),
  duplicate('สแกนซ้ำ'),
  empty('ไม่มีข้อมูล'),
  badFormat('รูปแบบบาร์โค้ดไม่ถูกต้อง'),
  busy('กำลังบันทึกรายการก่อนหน้า');

  const ScanOutcome(this.message);

  final String message;

  /// สำเร็จเท่านั้นที่ควรล้างช่องกรอก — กรณีอื่นเก็บค่าไว้ให้ผู้ใช้ตรวจ
  bool get shouldClearInput => this == ScanOutcome.accepted;

  /// ทุกกรณีที่ไม่สำเร็จควรให้สัญญาณตอบรับคนละแบบกับกรณีสำเร็จ
  bool get isFailure => this != ScanOutcome.accepted;
}

/// ผลของการตรวจจำนวน — null แปลว่าผ่าน ตามแบบเดียวกับ validator ของ Flutter
String? validateQuantity(String? raw, {int max = 999}) {
  final text = raw?.trim() ?? '';
  if (text.isEmpty) return 'กรุณากรอกจำนวน';

  final value = int.tryParse(text);
  if (value == null) return 'จำนวนต้องเป็นตัวเลข';
  if (value <= 0) return 'จำนวนต้องมากกว่า 0';
  if (value > max) return 'จำนวนต้องไม่เกิน $max';
  return null;
}

/// จัดรูปแบบบาร์โค้ดที่อ่านได้ ให้เทียบกันได้เสมอ
///
/// เครื่องสแกนบางรุ่นแถมช่องว่าง บางรุ่นส่งตัวพิมพ์เล็ก
/// ถ้าไม่จัดรูปแบบก่อน 'pal-1001' กับ 'PAL-1001 ' จะถูกนับเป็นคนละใบ
String normalizeBarcode(String raw) => raw.trim().toUpperCase();

/// รหัสพาเลทที่ระบบนี้ยอมรับ
bool isValidPalletCode(String normalized) =>
    RegExp(r'^PAL-\d{4,6}$').hasMatch(normalized);

/// รอบการสแกนหนึ่งรอบ
///
/// รับผิดชอบสามอย่าง: จัดรูปแบบ, กันซ้ำ, กันบันทึกซ้อน
/// ไม่รู้จักหน้าจอ ไม่รู้จักเครือข่าย
class ScanSession {
  ScanSession({required this.operatorName});

  final String operatorName;

  final List<String> _accepted = <String>[];
  final Set<String> _seen = <String>{};
  bool _busy = false;

  /// คืนสำเนาที่แก้ไม่ได้ ป้องกันคนนอกเพิ่มข้ามกฎ (D1.7)
  List<String> get accepted => List.unmodifiable(_accepted);

  int get count => _accepted.length;

  bool get busy => _busy;

  bool get isEmpty => _accepted.isEmpty;

  /// รับบาร์โค้ดหนึ่งตัว แล้วบอกว่าเกิดอะไรขึ้น
  ///
  /// ไม่โยน exception เพราะทุกกรณีที่นี่เป็นผลลัพธ์ปกติของงาน
  /// ไม่ใช่ความผิดปกติของระบบ (D1.14 หัวข้อ 8)
  ScanOutcome accept(String raw) {
    if (_busy) return ScanOutcome.busy;

    final code = normalizeBarcode(raw);
    if (code.isEmpty) return ScanOutcome.empty;
    if (!isValidPalletCode(code)) return ScanOutcome.badFormat;
    if (!_seen.add(code)) return ScanOutcome.duplicate;

    _accepted.add(code);
    return ScanOutcome.accepted;
  }

  /// ล็อกไม่ให้รับตัวใหม่ระหว่างกำลังบันทึก
  void beginSubmit() => _busy = true;

  /// ปลดล็อก — ต้องเรียกใน finally เสมอ (D1.15 หัวข้อ 7)
  void endSubmit() => _busy = false;

  /// ยกเลิกรายการที่รับไปแล้วหนึ่งใบ
  bool remove(String code) {
    final normalized = normalizeBarcode(code);
    if (!_seen.remove(normalized)) return false;
    _accepted.remove(normalized);
    return true;
  }
}
