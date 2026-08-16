// ignore_for_file: avoid_print
// D1.3 final / const / late
// รัน: dart run tool/dart_foundation/d1_03_final_const_late.dart

// const ระดับบนสุดของไฟล์: ค่าคงที่ที่รู้ตั้งแต่ยังไม่รันโปรแกรม
const String appName = 'WMS Companion';
const int maxScanPerBox = 50;

class Pallet {
  const Pallet(this.code, this.quantity);

  final String code;
  final int quantity;

  @override
  String toString() => 'Pallet($code, $quantity)';
}

void main() {
  print('=== final: ตั้งค่าได้ครั้งเดียว ===');
  final startedAt = DateTime.now(); // ค่าเพิ่งรู้ตอนรัน -> const ไม่ได้
  // startedAt = DateTime.now();    // error: ตั้งซ้ำไม่ได้
  print('$appName เริ่มทำงาน ${startedAt.year}');

  print('\n=== final ล็อกแค่ "ช่อง" ไม่ได้ล็อกข้างใน ===');
  final scanned = <String>['PAL-1001'];
  scanned.add('PAL-1002'); // ทำได้! เพราะ list ตัวเดิม แค่เพิ่มสมาชิก
  // scanned = <String>[];  // ทำไม่ได้ เพราะเปลี่ยนตัว list
  print('scanned = $scanned');

  print('\n=== const ล็อกลึกถึงข้างใน ===');
  const frozen = <String>['PAL-9001'];
  print('frozen = $frozen (แก้ไม่ได้ทั้งก้อน)');

  print('\n=== const object ตัวเดียวกันถูกใช้ซ้ำ ===');
  const a = Pallet('PAL-1001', 10);
  const b = Pallet('PAL-1001', 10);
  final c = Pallet('PAL-1001', 10);
  final d = Pallet('PAL-1001', 10);
  print('identical(a, b) = ${identical(a, b)}'); // true: ตัวเดียวกันเลย
  print('identical(c, d) = ${identical(c, d)}'); // false: สร้างใหม่คนละตัว

  print('\n=== late: สัญญาว่าจะใส่ค่าก่อนใช้ ===');
  final report = ShiftReport();
  report.start('กะเช้า');
  print(report.describe());

  print('\n=== late + ค่าเริ่มต้น: คำนวณครั้งแรกที่ถูกอ่านเท่านั้น ===');
  final lazy = LazyIndex();
  print('ยังไม่แตะ index — ยังไม่มีการคำนวณ');
  print('อ่านครั้งที่ 1: ${lazy.index.length} รายการ');
  print('อ่านครั้งที่ 2: ${lazy.index.length} รายการ (ไม่คำนวณซ้ำ)');
  print('maxScanPerBox = $maxScanPerBox');
}

class ShiftReport {
  late String shiftName; // ยังไม่มีค่า แต่สัญญาว่าจะใส่ก่อนอ่าน

  void start(String name) => shiftName = name;

  String describe() => 'รายงานของ $shiftName';
}

class LazyIndex {
  late final List<String> index = _buildIndex();

  List<String> _buildIndex() {
    print('  >> _buildIndex() ทำงานแล้ว');
    return ['A-01', 'A-02', 'B-01'];
  }
}
