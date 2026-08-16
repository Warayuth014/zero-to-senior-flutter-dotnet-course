// ignore_for_file: avoid_print
// D1.10 Enhanced Enum
// รัน: dart run tool/dart_foundation/d1_10_enum.dart

// enum ธรรมดา: รายชื่อสถานะที่เป็นไปได้ทั้งหมด
enum PickStatus { pending, inProgress, done, cancelled }

// enhanced enum: enum ที่มี field, constructor และ method ได้เหมือน class
enum TaskType {
  putaway('PUTAWAY', 'จัดเก็บ', true),
  retrieve('RETRIEVE', 'หยิบออก', true),
  ret('RETURN', 'คืนของ', false);

  const TaskType(this.wireValue, this.label, this.needsLocation);

  // wireValue = ค่าจริงที่ .NET API ส่งมา แยกออกจากชื่อที่เราใช้ในโค้ด
  final String wireValue;
  final String label;
  final bool needsLocation;

  static TaskType fromWire(String raw) {
    for (final type in TaskType.values) {
      if (type.wireValue == raw.toUpperCase()) return type;
    }
    throw ArgumentError('ไม่รู้จักงานชนิด "$raw"');
  }
}

void main() {
  print('=== enum ธรรมดา ===');
  print('ค่าทั้งหมด = ${PickStatus.values}');
  print('ชื่อ        = ${PickStatus.inProgress.name}');
  print('ลำดับ       = ${PickStatus.inProgress.index}');

  print('\n=== switch บน enum ต้องครบทุกค่า ไม่งั้น analyzer เตือน ===');
  for (final status in PickStatus.values) {
    print('  ${status.name.padRight(11)} -> ${messageFor(status)}');
  }

  print('\n=== enhanced enum: แต่ละค่ามีข้อมูลติดตัว ===');
  for (final type in TaskType.values) {
    print(
      '  ${type.wireValue.padRight(9)} | ${type.label.padRight(8)} '
      '| ต้องระบุช่องเก็บ: ${type.needsLocation}',
    );
  }

  print('\n=== แปลงค่าจาก API เป็น enum ที่ปลอดภัย ===');
  print(TaskType.fromWire('putaway').label);
  print(TaskType.fromWire('RETURN').label);
  try {
    TaskType.fromWire('TELEPORT');
  } on ArgumentError catch (error) {
    print('ถูกปฏิเสธ: ${error.message}');
  }
}

String messageFor(PickStatus status) => switch (status) {
  PickStatus.pending => 'รอเริ่มงาน',
  PickStatus.inProgress => 'กำลังหยิบ',
  PickStatus.done => 'เสร็จแล้ว',
  PickStatus.cancelled => 'ยกเลิก',
};
