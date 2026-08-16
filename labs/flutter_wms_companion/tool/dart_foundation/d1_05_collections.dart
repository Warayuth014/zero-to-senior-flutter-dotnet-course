// ignore_for_file: avoid_print
// D1.5 List / Set / Map
// รัน: dart run tool/dart_foundation/d1_05_collections.dart

void main() {
  print('=== List: เรียงตามลำดับ ซ้ำได้ ===');
  final scans = <String>['PAL-1001', 'PAL-1002', 'PAL-1001'];
  scans.add('PAL-1003');
  print('scans        = $scans');
  print('ตัวแรก        = ${scans.first}');
  print('จำนวนทั้งหมด  = ${scans.length}');
  print('มี PAL-1002?  = ${scans.contains('PAL-1002')}');

  print('\n=== Set: ไม่ซ้ำ ไม่รับประกันลำดับ ===');
  final uniqueScans = scans.toSet();
  print('uniqueScans  = $uniqueScans (${uniqueScans.length} ตัว)');

  print('\n=== Map: จับคู่ key -> value ===');
  final stockByCode = <String, int>{'PAL-1001': 12, 'PAL-1002': 4};
  stockByCode['PAL-1003'] = 9;
  print('stockByCode          = $stockByCode');
  print('ของ PAL-1002         = ${stockByCode['PAL-1002']}');
  print(
    'ของ PAL-9999         = ${stockByCode['PAL-9999']}',
  ); // null = ไม่มี key
  print('ถ้าไม่มีให้ใช้ 0      = ${stockByCode['PAL-9999'] ?? 0}');

  print('\n=== วนอ่านทีละตัว ===');
  for (final entry in stockByCode.entries) {
    print('  ${entry.key} -> ${entry.value} ชิ้น');
  }

  print('\n=== แปลง/กรอง/รวม โดยไม่ต้องเขียน for ===');
  final lowStock = stockByCode.entries
      .where((entry) => entry.value < 10)
      .map((entry) => entry.key)
      .toList();
  final totalStock = stockByCode.values.fold<int>(
    0,
    (sum, value) => sum + value,
  );
  print('ของใกล้หมด  = $lowStock');
  print('รวมทั้งหมด   = $totalStock ชิ้น');

  print('\n=== ระวัง: ตัวแปรสองตัวอาจชี้ list ก้อนเดียวกัน ===');
  final a = <String>['A'];
  final b = a; // ไม่ได้ copy
  b.add('B');
  print('a = $a  (เปลี่ยนตาม b ด้วย)');

  final copied = [...a]; // spread = สร้างก้อนใหม่
  copied.add('C');
  print('a = $a, copied = $copied');

  print('\n=== สร้าง list แบบมีเงื่อนไข ===');
  const isSupervisor = true;
  final menu = <String>[
    'รับเข้า',
    'หยิบสินค้า',
    if (isSupervisor) 'ตรวจนับ',
    ...['ตั้งค่า', 'ออกจากระบบ'],
  ];
  print('menu = $menu');
}
