import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/widget_basics/widget_basics_app.dart';

void main() {
  testWidgets('แดชบอร์ดแสดงสถิติเริ่มต้นและรายการงานครบ', (tester) async {
    await tester.pumpWidget(const WidgetBasicsApp());

    expect(find.text('จัดเก็บ PAL-1001'), findsOneWidget);
    expect(find.text('หยิบออก PAL-1002'), findsOneWidget);
    expect(find.text('ตรวจนับ โซน A'), findsOneWidget);
    expect(find.text('กดไปแล้ว 0 ครั้ง'), findsOneWidget);

    final remaining = tester.widget<StatCard>(
      find.byKey(const Key('stat-remaining')),
    );
    expect(remaining.value, '3');
  });

  testWidgets('กดงานหนึ่งใบแล้วยอดคงเหลือลดลง', (tester) async {
    await tester.pumpWidget(const WidgetBasicsApp());

    await tester.tap(find.text('จัดเก็บ PAL-1001'));
    await tester.pump();

    final remaining = tester.widget<StatCard>(
      find.byKey(const Key('stat-remaining')),
    );
    expect(remaining.value, '2');
    expect(find.text('กดไปแล้ว 1 ครั้ง'), findsOneWidget);
  });

  testWidgets('กดซ้ำที่ใบเดิมเป็นการยกเลิก ไม่ใช่การนับเพิ่ม', (tester) async {
    await tester.pumpWidget(const WidgetBasicsApp());

    await tester.tap(find.text('หยิบออก PAL-1002'));
    await tester.pump();
    await tester.tap(find.text('หยิบออก PAL-1002'));
    await tester.pump();

    final remaining = tester.widget<StatCard>(
      find.byKey(const Key('stat-remaining')),
    );
    expect(remaining.value, '3');
    // แต่จำนวนครั้งที่กดยังนับต่อเนื่อง เพราะเป็นคนละความหมายกัน
    expect(find.text('กดไปแล้ว 2 ครั้ง'), findsOneWidget);
  });

  testWidgets('TaskTile ผูกกับ id ของงานผ่าน ValueKey', (tester) async {
    await tester.pumpWidget(const WidgetBasicsApp());

    expect(find.byKey(const ValueKey<String>('T-01')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('T-03')), findsOneWidget);
  });

  testWidgets('TaskTile ไม่ถือ state เอง — สั่งจากภายนอกได้ทั้งหมด', (
    tester,
  ) async {
    var toggled = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskTile(
            task: const DashboardTask(
              id: 'T-99',
              title: 'งานทดสอบ',
              quantity: 7,
            ),
            done: true,
            onToggle: () => toggled++,
          ),
        ),
      ),
    );

    expect(find.text('T-99 · 7 ชิ้น'), findsOneWidget);
    await tester.tap(find.text('งานทดสอบ'));
    expect(toggled, 1);
  });
}
