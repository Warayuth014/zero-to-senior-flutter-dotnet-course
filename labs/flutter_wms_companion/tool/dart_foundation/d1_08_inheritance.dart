// ignore_for_file: avoid_print
// D1.8 Interface / Inheritance / Mixin
// รัน: dart run tool/dart_foundation/d1_08_inheritance.dart

// abstract class = แม่แบบที่สร้าง object ตรง ๆ ไม่ได้
// บังคับให้ลูกทุกตัวต้องมี run() และแชร์โค้ดส่วนกลางไว้ที่นี่
abstract class WarehouseTask {
  WarehouseTask(this.id);

  final String id;

  String get title;

  String run(); // ไม่มีตัว = ลูกต้องเขียนเอง

  String describe() => '[$id] $title -> ${run()}'; // แชร์ให้ลูกทุกตัว
}

class PutawayTask extends WarehouseTask {
  PutawayTask(super.id, this.location);

  final String location;

  @override
  String get title => 'จัดเก็บเข้าช่อง';

  @override
  String run() => 'นำพาเลทไปที่ $location';
}

class PickTask extends WarehouseTask {
  PickTask(super.id, this.quantity);

  final int quantity;

  @override
  String get title => 'หยิบสินค้า';

  @override
  String run() => 'หยิบ $quantity ชิ้นออกจากช่องเก็บ';
}

// interface: สนใจแค่ "ต้องมี method อะไร" ไม่ยืมโค้ดแม่มาใช้
// ใน Dart ทุก class เป็น interface ได้ทันทีด้วยคำว่า implements
abstract interface class Printable {
  String toReceipt();
}

// mixin: ก้อนความสามารถที่แปะให้หลาย class ได้ โดยไม่ใช่แม่-ลูก
mixin Timestamped {
  final DateTime createdAt = DateTime(2026, 1, 1, 9, 0);

  String get stamp =>
      '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
}

class CountTask extends WarehouseTask with Timestamped implements Printable {
  CountTask(super.id, this.expected);

  final int expected;

  @override
  String get title => 'ตรวจนับ';

  @override
  String run() => 'นับให้ครบ $expected ชิ้น';

  @override
  String toReceipt() => 'ใบตรวจนับ $id เวลา $stamp';
}

void main() {
  final tasks = <WarehouseTask>[
    PutawayTask('T-01', 'A-01-02'),
    PickTask('T-02', 5),
    CountTask('T-03', 30),
  ];

  print('=== ตัวแปรชนิดแม่ เก็บลูกได้ทุกแบบ (polymorphism) ===');
  for (final task in tasks) {
    print(task.describe()); // เรียกชื่อเดียว แต่พฤติกรรมต่างกันตามชนิดจริง
  }

  print('\n=== เลือกเฉพาะตัวที่ทำ interface นั้นได้ ===');
  // whereType<T>() คัดเฉพาะสมาชิกที่เป็นชนิดนั้น และเปลี่ยนชนิดให้เลย
  for (final printable in tasks.whereType<Printable>()) {
    print(printable.toReceipt());
  }
  // หมายเหตุ: เขียน if (task is Printable) แล้วเรียก task.toReceipt() ตรง ๆ ไม่ได้
  // เพราะ Printable ไม่ใช่ลูกของ WarehouseTask — Dart จึงไม่เลื่อนชนิดให้อัตโนมัติ

  print('\n=== mixin แปะความสามารถโดยไม่ต้องเป็นลูกของใคร ===');
  final count = tasks.whereType<CountTask>().first;
  print('createdAt stamp = ${count.stamp}');

  print('\n=== ตรวจชนิดจริงตอนรัน ===');
  // ประกาศเป็น Object เพื่อจำลองค่าที่ยังไม่รู้ชนิด เช่น ข้อมูลจาก API
  final Object item = tasks[1];
  print('item is PickTask       = ${item is PickTask}');
  print('item is PutawayTask    = ${item is PutawayTask}');
  print('item is WarehouseTask  = ${item is WarehouseTask}');
  print('item is Printable      = ${item is Printable}');
}
