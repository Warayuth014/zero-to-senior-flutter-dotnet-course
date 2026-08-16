// ignore_for_file: avoid_print
// D1.11 Callbacks
// รัน: dart run tool/dart_foundation/d1_11_callbacks.dart

// callback = ฟังก์ชันที่เราส่งให้คนอื่นเก็บไว้ "เรียกทีหลัง"
// ScanField ไม่รู้ว่าใครใช้มัน รู้แค่ว่าเมื่อสแกนสำเร็จให้เรียก onSubmitted
class ScanField {
  ScanField({required this.onSubmitted, this.onError});

  final void Function(String code) onSubmitted;
  final void Function(String message)? onError; // ไม่บังคับ

  void simulateScan(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) {
      onError?.call('บาร์โค้ดว่าง'); // ?. = ถ้าไม่มีคนฟัง ก็ไม่ต้องเรียก
      return;
    }
    onSubmitted(code);
  }
}

// typedef ตั้งชื่อให้ชนิดของฟังก์ชัน อ่านง่ายกว่าเขียนยาว ๆ ซ้ำ
typedef QuantityValidator = String? Function(int value);

String? notNegative(int value) => value < 0 ? 'จำนวนติดลบไม่ได้' : null;

void main() {
  print('=== ส่งฟังก์ชันเข้าไปให้เรียกทีหลัง ===');
  final field = ScanField(
    onSubmitted: (code) => print('  รับบาร์โค้ด: $code'),
    onError: (message) => print('  ผิดพลาด: $message'),
  );
  field.simulateScan(' pal-1001 ');
  field.simulateScan('');

  print('\n=== callback ที่ไม่ส่งมา ก็ไม่พัง ===');
  final silent = ScanField(onSubmitted: (code) => print('  รับ: $code'));
  silent.simulateScan(''); // ไม่มี onError -> เงียบ ไม่ crash

  print('\n=== เก็บ callback ไว้ในตัวแปร ===');
  final QuantityValidator validate = notNegative;
  print('  validate(5)  = ${validate(5)}');
  print('  validate(-2) = ${validate(-2)}');

  print('\n=== closure จำค่ารอบตัวไว้ได้ ===');
  var received = 0;
  final counter = ScanField(
    onSubmitted: (_) {
      received++; // แก้ตัวแปรนอกฟังก์ชันได้ เพราะ closure จับตัวแปรไว้
      print('  สแกนสะสม $received รายการ');
    },
  );
  counter.simulateScan('PAL-1001');
  counter.simulateScan('PAL-1002');

  print('\n=== กับดักคลาสสิก: ใส่วงเล็บ = เรียกทันที ===');
  final wrong = ScanField(onSubmitted: (code) => logIt(code));
  final right = ScanField(onSubmitted: logIt); // ส่งตัวฟังก์ชันไปตรง ๆ
  wrong.simulateScan('PAL-A');
  right.simulateScan('PAL-B');
  // ถ้าเขียน onSubmitted: logIt('x') จะ error เพราะนั่นคือ "ผลลัพธ์" ไม่ใช่ฟังก์ชัน
}

void logIt(String code) => print('  logIt: $code');
