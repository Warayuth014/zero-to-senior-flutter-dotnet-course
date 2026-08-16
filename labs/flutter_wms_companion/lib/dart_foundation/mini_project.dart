/// D1.20 Dart Mini Project — โปรแกรมเล็ก ๆ ที่รวมทุกอย่างของ Dart Foundation
///
/// ยังไม่มี Flutter, ไม่มี widget, ไม่มีเครือข่ายจริง
/// มีแค่ Dart ล้วน ๆ แต่โครงสร้างเหมือนที่แอปจริงใช้:
/// ข้อมูลดิบ -> ตรวจ -> model -> ประมวลผล -> สรุปผล
library;

import 'dart:convert';

/// ชนิดของงานในคลัง (D1.10 enhanced enum)
enum TaskType {
  putaway('PUTAWAY', 'จัดเก็บ'),
  retrieve('RETRIEVE', 'หยิบออก');

  const TaskType(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TaskType fromWire(String raw) {
    for (final type in values) {
      if (type.wireValue == raw.toUpperCase()) return type;
    }
    throw FormatException('ไม่รู้จักงานชนิด "$raw"');
  }
}

/// ข้อผิดพลาดของโดเมนนี้โดยเฉพาะ (D1.14)
class TaskFormatException implements Exception {
  TaskFormatException(this.message);
  final String message;
  @override
  String toString() => 'TaskFormatException: $message';
}

/// งานหนึ่งใบ (D1.6 class + D1.13 null safety)
class WarehouseTask {
  WarehouseTask({
    required this.id,
    required this.type,
    required this.palletCode,
    required this.quantity,
    this.location,
  });

  /// ทางเข้าเดียวจากข้อมูลดิบ (D1.19 JSON/cast)
  factory WarehouseTask.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final palletCode = json['palletCode'];
    if (id is! String || type is! String || palletCode is! String) {
      throw TaskFormatException('ฟิลด์ id/type/palletCode ต้องเป็นข้อความ');
    }

    final rawQuantity = json['quantity'];
    final quantity = switch (rawQuantity) {
      final int value => value,
      final String value when int.tryParse(value) != null => int.parse(value),
      _ => throw TaskFormatException('quantity ไม่ใช่จำนวนเต็ม: $rawQuantity'),
    };
    if (quantity <= 0) {
      throw TaskFormatException('quantity ต้องมากกว่า 0 (ได้ $quantity)');
    }

    return WarehouseTask(
      id: id,
      type: TaskType.fromWire(type),
      palletCode: palletCode.trim().toUpperCase(),
      quantity: quantity,
      location: json['location'] as String?,
    );
  }

  final String id;
  final TaskType type;
  final String palletCode;
  final int quantity;
  final String? location;

  bool get needsLocation => type == TaskType.putaway && location == null;

  @override
  String toString() =>
      '[$id] ${type.label} $palletCode x$quantity @ ${location ?? 'ยังไม่ระบุ'}';
}

/// ผลของการอ่านข้อมูลดิบทั้งชุด (D1.12 record แบบมีชื่อ)
typedef ParseReport = ({List<WarehouseTask> tasks, List<String> errors});

/// อ่าน JSON ทั้งก้อน โดยแถวที่เสียไม่ทำให้ทั้งชุดพัง
ParseReport parseTasks(String rawJson) {
  final tasks = <WarehouseTask>[];
  final errors = <String>[];

  Object? decoded;
  try {
    decoded = jsonDecode(rawJson);
  } on FormatException catch (error) {
    return (
      tasks: tasks,
      errors: <String>['JSON เสียทั้งก้อน: ${error.message}'],
    );
  }

  if (decoded is! List) {
    return (tasks: tasks, errors: <String>['คาดว่าเป็น list ของงาน']);
  }

  for (var index = 0; index < decoded.length; index++) {
    final row = decoded[index];
    if (row is! Map<String, dynamic>) {
      errors.add('แถวที่ $index ไม่ใช่ object');
      continue;
    }
    try {
      tasks.add(WarehouseTask.fromJson(row));
    } on TaskFormatException catch (error) {
      errors.add('แถวที่ $index: ${error.message}');
    } on FormatException catch (error) {
      errors.add('แถวที่ $index: ${error.message}');
    }
  }

  return (tasks: tasks, errors: errors);
}

/// สรุปงานตามชนิด (D1.5 collections)
Map<TaskType, int> quantityByType(List<WarehouseTask> tasks) {
  final result = <TaskType, int>{};
  for (final task in tasks) {
    result[task.type] = (result[task.type] ?? 0) + task.quantity;
  }
  return result;
}

/// จำลองการส่งงานขึ้น server ทีละใบ (D1.15 async + D1.11 callback)
Future<int> dispatchAll(
  List<WarehouseTask> tasks, {
  required Future<bool> Function(WarehouseTask task) send,
  void Function(WarehouseTask task, bool accepted)? onResult,
}) async {
  var accepted = 0;
  for (final task in tasks) {
    final ok = await send(task);
    if (ok) accepted++;
    onResult?.call(task, ok);
  }
  return accepted;
}
