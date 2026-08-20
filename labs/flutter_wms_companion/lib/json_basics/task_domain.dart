import 'json_read.dart';
import 'task_dto.dart';

/// สถานะที่แอปรู้จัก
///
/// มี unknown อยู่ด้วยเพราะเซิร์ฟเวอร์เพิ่มสถานะใหม่ได้ตลอด
/// และแอปรุ่นเก่าที่ยังอยู่บนเครื่องต้องไม่พังเพราะเจอค่าที่ไม่รู้จัก
enum TaskStatus {
  pending('PENDING'),
  working('WORKING'),
  done('DONE'),
  unknown('');

  const TaskStatus(this.wireValue);

  /// ค่าที่ใช้คุยกับเซิร์ฟเวอร์ — แยกจากชื่อใน Dart โดยตั้งใจ
  /// ถ้าใช้ `name` ตรง ๆ วันที่มีคนเปลี่ยนชื่อ enum จะพังทั้งสัญญา
  final String wireValue;

  /// สถานะที่ไม่รู้จัก ห้ามให้ทำงานต่อ เพราะไม่รู้ว่ามันแปลว่าอะไร
  bool get canWorkOn => this == TaskStatus.pending || this == TaskStatus.working;
}

TaskStatus parseTaskStatus(String raw) => switch (raw.trim().toUpperCase()) {
  'PENDING' => TaskStatus.pending,
  'WORKING' => TaskStatus.working,
  // ระบบเก่าส่ง COMPLETED แทน DONE — รวมชื่อเล่นไว้ที่เดียว
  'DONE' || 'COMPLETED' => TaskStatus.done,
  _ => TaskStatus.unknown,
};

/// งานหนึ่งชิ้นในภาษาของธุรกิจ ไม่ใช่ภาษาของสาย
///
/// ต่างจาก TaskDto สามอย่าง — status เป็น enum, ค่าถูกตรวจแล้ว
/// และไม่มีอะไรที่หน้าจอต้องตีความเองอีก
class Task {
  const Task({
    required this.id,
    required this.palletCode,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String palletCode;
  final int quantity;
  final TaskStatus status;
  final DateTime createdAt;
  final String? note;

  Task copyWith({int? quantity, TaskStatus? status}) => Task(
    id: id,
    palletCode: palletCode,
    quantity: quantity ?? this.quantity,
    status: status ?? this.status,
    createdAt: createdAt,
    note: note,
  );

  /// ล้างหมายเหตุ — ต้องมีเมธอดแยก เพราะ copyWith ตั้งค่าเป็น null ไม่ได้
  /// (`note ?? this.note` แปลว่า "ไม่ส่งมา = ใช้ของเดิม" เสมอ)
  Task clearNote() => Task(
    id: id,
    palletCode: palletCode,
    quantity: quantity,
    status: status,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          other.id == id &&
          other.palletCode == palletCode &&
          other.quantity == quantity &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.note == note;

  @override
  int get hashCode =>
      Object.hash(id, palletCode, quantity, status, createdAt, note);
}

/// แปลงจากสิ่งที่เซิร์ฟเวอร์ส่งมา เป็นสิ่งที่แอปใช้งานได้
///
/// นี่คือด่านสุดท้ายก่อนข้อมูลจะเข้าไปในแอป — กฎทางธุรกิจที่ตรวจตรงนี้
/// จะไม่ต้องถูกตรวจซ้ำที่หน้าจอ
Task toTask(TaskDto dto, {String path = ''}) {
  if (dto.quantity <= 0) {
    throw ContractException(
      path.isEmpty ? 'quantity' : '$path.quantity',
      'จำนวนต้องมากกว่าศูนย์ แต่ได้ ${dto.quantity}',
    );
  }

  return Task(
    id: dto.id,
    palletCode: dto.palletCode,
    quantity: dto.quantity,
    status: parseTaskStatus(dto.status),
    createdAt: dto.createdAt,
    note: dto.note,
  );
}
