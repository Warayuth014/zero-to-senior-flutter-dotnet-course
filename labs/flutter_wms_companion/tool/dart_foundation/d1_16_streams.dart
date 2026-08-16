// ignore_for_file: avoid_print
// D1.16 Stream & Events
// รัน: dart run tool/dart_foundation/d1_16_streams.dart

import 'dart:async';

// Future = ค่าเดียวในอนาคต
// Stream = ค่าหลายค่าที่ทยอยมาเรื่อย ๆ เช่น การสแกนของพนักงานทั้งกะ
Stream<String> scanFeed() async* {
  for (final code in <String>['PAL-1001', 'PAL-1002', 'PAL-1003']) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    yield code; // ส่งออกทีละตัว
  }
}

Future<void> main() async {
  print('=== อ่าน stream ด้วย await for ===');
  await for (final code in scanFeed()) {
    print('  ได้รับ $code');
  }

  print('\n=== แปลง/กรองก่อนถึงผู้ใช้ ===');
  final bigOnly = scanFeed()
      .map((code) => code.replaceFirst('PAL-', ''))
      .where((number) => int.parse(number) >= 1002);
  await for (final number in bigOnly) {
    print('  ผ่านเงื่อนไข: $number');
  }

  print('\n=== StreamController: เราเป็นคนป้อนเหตุการณ์เอง ===');
  final controller = StreamController<String>();
  final subscription = controller.stream.listen(
    (event) => print('  ผู้ฟังได้รับ: $event'),
    onDone: () => print('  ปิด stream แล้ว'),
  );
  controller.add('เริ่มรอบตรวจนับ');
  controller.add('สแกน PAL-1001');
  await controller.close(); // ปิดเมื่อเลิกใช้
  await subscription.cancel(); // ยกเลิกการฟัง = คืนทรัพยากร

  print('\n=== single-subscription ฟังได้คนเดียว ===');
  final single = StreamController<int>();
  single.stream.listen((value) => print('  ผู้ฟัง A: $value'));
  try {
    single.stream.listen((value) => print('  ผู้ฟัง B: $value'));
  } on StateError {
    print('  ผู้ฟังคนที่สองถูกปฏิเสธ (ต้องใช้ broadcast)');
  }
  await single.close();

  print('\n=== broadcast ฟังพร้อมกันได้หลายคน ===');
  final bus = StreamController<String>.broadcast();
  bus.stream.listen((event) => print('  หน้าจอรายการ: $event'));
  bus.stream.listen((event) => print('  แถบแจ้งเตือน: $event'));
  bus.add('งานใหม่เข้ามา 1 รายการ');
  await Future<void>.delayed(Duration.zero);
  await bus.close();

  print('\n=== error ใน stream ไม่ทำให้โปรแกรมตาย ถ้ามีคนจับ ===');
  final risky = StreamController<int>();
  risky.stream.listen(
    (value) => print('  ค่า: $value'),
    onError: (Object error) => print('  จับ error: $error'),
  );
  risky.add(1);
  risky.addError('เครื่องสแกนหลุด');
  risky.add(2);
  await risky.close();
  await Future<void>.delayed(Duration.zero);

  print('\n=== กฎที่ต้องจำ ===');
  print('  ใครสร้าง controller คนนั้นต้อง close()');
  print('  ใคร listen คนนั้นต้อง cancel() เมื่อเลิกใช้');
}
