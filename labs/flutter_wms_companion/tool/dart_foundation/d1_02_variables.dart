// ignore_for_file: avoid_print
// D1.2 Variables & Data Types
// รัน: dart run tool/dart_foundation/d1_02_variables.dart

void main() {
  // ---- ชนิดพื้นฐานที่ใช้บ่อยที่สุด 4 ตัว ----
  String barcode = 'PAL-1001';
  int quantity = 12;
  double weightKg = 3.5;
  bool isChecked = false;

  print('barcode  = $barcode  (${barcode.runtimeType})');
  print('quantity = $quantity  (${quantity.runtimeType})');
  print('weightKg = $weightKg  (${weightKg.runtimeType})');
  print('isChecked= $isChecked  (${isChecked.runtimeType})');

  // ---- var ให้ Dart เดาชนิดให้ แต่ชนิดยังตายตัว ----
  var location = 'A-01-02';
  location = 'A-01-03'; // เปลี่ยนค่าได้เพราะยังเป็น String
  // location = 5;      // ถ้าเปิดบรรทัดนี้ จะ error ตั้งแต่ยังไม่รัน
  print('location = $location');

  // ---- num คือพ่อแม่ของ int กับ double ----
  num anyNumber = 7;
  anyNumber = 7.5;
  print('anyNumber= $anyNumber (${anyNumber.runtimeType})');

  // ---- แปลงชนิด: ข้อความจากเครื่องสแกนเป็นตัวเลข ----
  final scannedText = '25';
  final scannedQty = int.parse(scannedText);
  final maybeQty = int.tryParse('ยี่สิบห้า'); // คืน null แทนที่จะพัง
  print('scannedQty = ${scannedQty + 1}');
  print('maybeQty   = $maybeQty');

  // ---- Object? ปลอดภัยกว่า dynamic ----
  Object? fromServer = 42;
  if (fromServer is int) {
    // ใน if นี้ Dart รู้แล้วว่าเป็น int จึงบวกเลขได้
    print('fromServer + 1 = ${fromServer + 1}');
  }

  // ---- String interpolation ----
  print('$barcode มี $quantity ชิ้น น้ำหนักรวม ${weightKg * quantity} kg');
}
