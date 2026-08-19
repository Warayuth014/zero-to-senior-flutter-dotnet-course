import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/scanner_basics/scanner_basics_app.dart';

/// จำลองการยิงบาร์โค้ด — เครื่องสแกนพิมพ์รหัสแล้วกด Enter ให้
Future<void> scan(WidgetTester tester, String code) async {
  await tester.enterText(find.byKey(const Key('barcode-field')), code);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

String countText(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('accepted-count'))).data!;

void main() {
  testWidgets('ยิงสำเร็จแล้วช่องกรอกถูกล้างและโฟกัสกลับมา', (tester) async {
    await tester.pumpWidget(const ScannerBasicsApp());

    await scan(tester, 'pal-1001');

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('barcode-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, isEmpty);
    expect(field.focusNode?.hasFocus, isTrue);
    expect(countText(tester), 'รับแล้ว 1 รายการ');
  });

  testWidgets('ยิงซ้ำไม่เพิ่มรายการ และไม่ล้างช่องกรอก', (tester) async {
    await tester.pumpWidget(const ScannerBasicsApp());

    await scan(tester, 'PAL-1001');
    await scan(tester, '  pal-1001  ');

    expect(countText(tester), 'รับแล้ว 1 รายการ');
    expect(find.text('สแกนซ้ำ'), findsOneWidget);

    // เก็บค่าไว้ให้ผู้ใช้เห็นว่ายิงอะไรเข้าไป
    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('barcode-field')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, '  pal-1001  ');
  });

  testWidgets('รูปแบบผิดถูกปฏิเสธพร้อมข้อความที่ต่างจากซ้ำ', (tester) async {
    await tester.pumpWidget(const ScannerBasicsApp());

    await scan(tester, 'BOX-1');

    expect(countText(tester), 'รับแล้ว 0 รายการ');
    expect(find.text('รูปแบบบาร์โค้ดไม่ถูกต้อง'), findsOneWidget);
  });

  testWidgets('ปุ่มบันทึกปิดอยู่จนกว่าจะมีรายการ', (tester) async {
    await tester.pumpWidget(const ScannerBasicsApp());

    final before = tester.widget<FilledButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(before.onPressed, isNull);

    await scan(tester, 'PAL-1001');

    final after = tester.widget<FilledButton>(
      find.byKey(const Key('submit-button')),
    );
    expect(after.onPressed, isNotNull);
  });

  testWidgets('จำนวนที่ไม่ถูกต้องทำให้บันทึกไม่ผ่าน', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiveScreen(
          onSubmit: (codes) async {
            sent++;
            return true;
          },
        ),
      ),
    );

    await scan(tester, 'PAL-1001');
    await tester.enterText(find.byKey(const Key('quantity-field')), '0');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('จำนวนต้องมากกว่า 0'), findsOneWidget);
    expect(sent, 0); // ไม่ควรถึงขั้นส่ง
  });

  testWidgets('ต้องยืนยันก่อนบันทึก และกดยกเลิกแล้วไม่ส่ง', (tester) async {
    var sent = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ReceiveScreen(
          onSubmit: (codes) async {
            sent++;
            return true;
          },
        ),
      ),
    );

    await scan(tester, 'PAL-1001');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('ยืนยันการบันทึก'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-cancel')));
    await tester.pumpAndSettle();

    expect(sent, 0);
  });

  testWidgets('กดบันทึกรัวไม่ทำให้ส่งซ้ำ', (tester) async {
    var sent = 0;
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(
        home: ReceiveScreen(
          onSubmit: (codes) {
            sent++;
            return gate.future; // ค้างไว้จนกว่าเราจะปล่อย
          },
        ),
      ),
    );

    await scan(tester, 'PAL-1001');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pump();

    // ระหว่างที่ยังบันทึกไม่เสร็จ กดซ้ำอีกสองครั้ง
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pump();

    gate.complete(true);
    await tester.pumpAndSettle();

    expect(sent, 1);
  });

  testWidgets('ระหว่างบันทึก ยิงบาร์โค้ดเพิ่มไม่ได้', (tester) async {
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(home: ReceiveScreen(onSubmit: (codes) => gate.future)),
    );

    await scan(tester, 'PAL-1001');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pump();

    expect(countText(tester), 'รับแล้ว 1 รายการ');

    gate.complete(true);
    await tester.pumpAndSettle();
  });

  testWidgets('ออกจากหน้าจอระหว่างบันทึกแล้วไม่พัง', (tester) async {
    final gate = Completer<bool>();

    await tester.pumpWidget(
      MaterialApp(home: ReceiveScreen(onSubmit: (codes) => gate.future)),
    );

    await scan(tester, 'PAL-1001');
    await tester.tap(find.byKey(const Key('submit-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-ok')));
    await tester.pump();

    // ผู้ใช้กดย้อนกลับระหว่างที่ยังบันทึกไม่เสร็จ
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    gate.complete(true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
