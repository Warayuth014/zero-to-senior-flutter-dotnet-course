// ignore_for_file: avoid_print
// D1.6 Class / Object / Constructor
// รัน: dart run tool/dart_foundation/d1_06_class.dart

class Pallet {
  // constructor หลัก: this.code คือทางลัดของ "รับค่ามาแล้วเก็บลง field code"
  Pallet({required this.code, required this.location, this.quantity = 0});

  // named constructor: ทางเข้าเพิ่มเติมที่ตั้งชื่อได้
  Pallet.empty(String code) : this(code: code, location: 'ยังไม่จัดเก็บ');

  // factory: เลือกได้ว่าจะสร้างวัตถุแบบไหน หรือคืนตัวเดิม
  factory Pallet.fromScan(String rawText) {
    final parts = rawText.split('|');
    if (parts.length < 3) {
      return Pallet.empty(parts.first);
    }
    return Pallet(
      code: parts[0],
      location: parts[1],
      quantity: int.tryParse(parts[2]) ?? 0,
    );
  }

  final String code;
  final String location;
  int quantity;

  void receive(int amount) {
    if (amount <= 0) return;
    quantity += amount;
  }

  // toString ทำให้ print(object) อ่านรู้เรื่อง
  @override
  String toString() => 'Pallet($code @ $location, $quantity ชิ้น)';
}

void main() {
  print('=== สร้าง object จาก class ===');
  final a = Pallet(code: 'PAL-1001', location: 'A-01-02', quantity: 10);
  print(a);

  print('\n=== named constructor ===');
  final b = Pallet.empty('PAL-1002');
  print(b);

  print('\n=== factory constructor: แปลงข้อความจากเครื่องสแกน ===');
  print(Pallet.fromScan('PAL-1003|B-02-01|25'));
  print(Pallet.fromScan('PAL-1004')); // ข้อมูลไม่ครบ -> ตกไปทาง empty

  print('\n=== method เปลี่ยนสถานะภายใน object ===');
  a.receive(5);
  a.receive(-99); // ถูกปฏิเสธ
  print(a);

  print('\n=== object คนละตัว ถึงค่าจะเท่ากัน ===');
  final c = Pallet(code: 'PAL-1001', location: 'A-01-02', quantity: 15);
  print('a == c ? ${a == c}'); // false เพราะยังไม่ได้สอนให้เทียบด้วยค่า
  print('a.code == c.code ? ${a.code == c.code}');
}
