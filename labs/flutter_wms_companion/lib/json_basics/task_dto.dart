import 'json_read.dart';

/// สิ่งที่เซิร์ฟเวอร์ส่งมาจริง — ไม่ใช่สิ่งที่แอปอยากได้
///
/// DTO สะท้อนหน้าตาของข้อมูลบนสาย ไม่ตัดสินอะไรทั้งนั้น
/// `status` จึงยังเป็น String ไม่ใช่ enum เพราะเซิร์ฟเวอร์อาจส่งค่าที่เราไม่รู้จัก
class TaskDto {
  const TaskDto({
    required this.id,
    required this.palletCode,
    required this.quantity,
    required this.status,
    required this.createdAt,
    this.note,
  });

  factory TaskDto.fromJson(Map<String, dynamic> json, {String path = ''}) =>
      TaskDto(
        id: requireString(json, 'id', path: path),
        palletCode: requireString(json, 'palletCode', path: path),
        quantity: requireInt(json, 'quantity', path: path),
        status: requireString(json, 'status', path: path),
        createdAt: requireUtcTime(json, 'createdAt', path: path),
        note: readString(json, 'note', path: path),
      );

  final String id;
  final String palletCode;
  final int quantity;
  final String status;
  final DateTime createdAt;
  final String? note;
}

/// คำสั่งที่ส่งขึ้นไป — คนละก้อนกับที่รับลงมา
///
/// ไม่ใช้ TaskDto ตัวเดียวกันทั้งขึ้นและลง เพราะสองทิศทางมี field ไม่เหมือนกัน
/// เช่นตอนส่งไม่มี createdAt แต่มี commandId ที่ตอนรับไม่มี
class CompleteTaskRequest {
  const CompleteTaskRequest({
    required this.taskId,
    required this.quantity,
    required this.commandId,
    this.note,
  });

  final String taskId;
  final int quantity;
  final String commandId;
  final String? note;

  Map<String, Object?> toJson() => {
    'taskId': taskId,
    'quantity': quantity,
    'commandId': commandId,
    // ส่งคีย์ไปเสมอแม้ค่าเป็น null เพื่อให้เซิร์ฟเวอร์แยกได้ว่า
    // "ตั้งใจล้างหมายเหตุ" ต่างจาก "ไม่ได้แตะหมายเหตุ"
    'note': note,
  };
}

/// ซองที่ห่อรายการมา พร้อมข้อมูลว่ามีทั้งหมดกี่รายการ
///
/// items.length คือจำนวนในหน้านี้ ส่วน totalCount คือจำนวนทั้งหมดที่ตรงเงื่อนไข
/// สองค่านี้ไม่เท่ากันเมื่อข้อมูลถูกแบ่งหน้า
class TaskPageDto {
  const TaskPageDto({required this.items, required this.totalCount});

  factory TaskPageDto.fromJson(Map<String, dynamic> json) {
    final rawItems = requireList(json, 'items');
    final items = <TaskDto>[];
    for (var index = 0; index < rawItems.length; index++) {
      // ส่ง path ลงไปด้วย เพื่อให้ error บอกได้ว่าพังที่แถวไหน
      final path = 'items[$index]';
      items.add(TaskDto.fromJson(requireMap(rawItems[index], path), path: path));
    }

    final totalCount = requireInt(json, 'totalCount');
    if (totalCount < items.length) {
      throw const ContractException(
        'totalCount',
        'จำนวนทั้งหมดต้องไม่น้อยกว่าจำนวนในหน้านี้',
      );
    }

    return TaskPageDto(items: items, totalCount: totalCount);
  }

  final List<TaskDto> items;
  final int totalCount;

  bool get hasMore => items.length < totalCount;
}
