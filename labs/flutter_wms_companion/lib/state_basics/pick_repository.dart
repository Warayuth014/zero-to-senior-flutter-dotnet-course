/// Lab ของ Part 4 — สัญญาว่าที่เก็บข้อมูลต้องทำอะไรได้บ้าง
///
/// ประกาศเป็นสัญญา (D1.8) เพื่อให้สลับระหว่างตัวจริงกับตัวปลอมได้
/// โดยที่ store ไม่รู้เลยว่ากำลังคุยกับตัวไหน
library;

class PickLine {
  const PickLine({
    required this.id,
    required this.palletCode,
    required this.quantity,
    this.done = false,
  });

  final String id;
  final String palletCode;
  final int quantity;
  final bool done;

  /// สร้างสำเนาที่แก้บางค่า — ไม่แก้ตัวเดิม (D1.5)
  PickLine copyWith({bool? done}) => PickLine(
    id: id,
    palletCode: palletCode,
    quantity: quantity,
    done: done ?? this.done,
  );

  @override
  String toString() => '$id($palletCode x$quantity, done=$done)';
}

/// ข้อผิดพลาดที่ตั้งใจให้เกิดได้จริงในงาน ไม่ใช่บั๊กของเรา (D1.14)
class PickException implements Exception {
  const PickException(this.message, {this.outcomeUnknown = false});

  final String message;

  /// true เมื่อไม่รู้ว่า server ทำสำเร็จหรือยัง เช่นหมดเวลารอ
  final bool outcomeUnknown;
}

abstract interface class PickRepository {
  Future<List<PickLine>> fetchLines();

  /// ปิดงานหนึ่งบรรทัด
  ///
  /// [commandId] คือรหัสประจำคำสั่ง ส่งซ้ำด้วยรหัสเดิมแล้วต้องไม่บันทึกซ้ำ
  Future<void> markDone(String lineId, {required String commandId});
}
