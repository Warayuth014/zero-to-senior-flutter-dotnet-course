import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/layout_basics/layout_basics_app.dart';

/// ตั้งขนาดหน้าจอที่จะใช้ทดสอบ แล้วคืนค่าเดิมให้อัตโนมัติเมื่อจบ
Future<void> pumpAtWidth(
  WidgetTester tester,
  double width, {
  double height = 900,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const LayoutBasicsApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('จอกว้าง: แถบสรุปเรียงเป็นแถวเดียว', (tester) async {
    await pumpAtWidth(tester, 900);

    final bar = tester.widget<SummaryBar>(find.byKey(const Key('summary-bar')));
    expect(bar.stacked, isFalse);
    expect(bar.lineCount, 4);
    expect(bar.totalQuantity, 5288);
  });

  testWidgets('จอแคบแบบ PDA: แถบสรุปซ้อนลงล่าง', (tester) async {
    await pumpAtWidth(tester, 360);

    final bar = tester.widget<SummaryBar>(find.byKey(const Key('summary-bar')));
    expect(bar.stacked, isTrue);
  });

  testWidgets('ชื่อสินค้ายาวไม่ทำให้ layout ล้น', (tester) async {
    await pumpAtWidth(tester, 360);

    // ถ้าเกิด RenderFlex overflow เฟรมเวิร์กจะบันทึกเป็น exception
    expect(tester.takeException(), isNull);

    final longName = tester.widget<Text>(
      find.text('กล่องกระดาษลูกฟูก ขนาดใหญ่พิเศษ สำหรับงานส่งออก'),
    );
    expect(longName.overflow, TextOverflow.ellipsis);
    expect(longName.maxLines, 1); // จอแคบตัดเหลือบรรทัดเดียว
  });

  testWidgets('จอกว้างให้ชื่อสินค้าได้สองบรรทัด', (tester) async {
    await pumpAtWidth(tester, 900);

    final longName = tester.widget<Text>(
      find.text('กล่องกระดาษลูกฟูก ขนาดใหญ่พิเศษ สำหรับงานส่งออก'),
    );
    expect(longName.maxLines, 2);
  });

  testWidgets('ปุ่มยืนยันสูงพอสำหรับมือที่ใส่ถุงมือ', (tester) async {
    await pumpAtWidth(tester, 360);

    final size = tester.getSize(
      find.byKey(const ValueKey<String>('confirm-PAL-1001')),
    );
    expect(size.height, greaterThanOrEqualTo(Breakpoints.minTapTarget));
  });

  testWidgets('รายการเลื่อนได้และแต่ละใบผูกกับรหัสพาเลท', (tester) async {
    await pumpAtWidth(tester, 360, height: 640);

    expect(find.byKey(const ValueKey<String>('PAL-1001')), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('PAL-1004')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
