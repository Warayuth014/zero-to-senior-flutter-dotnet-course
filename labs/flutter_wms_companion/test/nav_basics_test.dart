import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/nav_basics/nav_basics_app.dart';
import 'package:flutter_wms_companion/nav_basics/nav_models.dart';

void main() {
  late AppSession session;

  setUp(() {
    session = AppSession();
    addTearDown(session.dispose);
  });

  Future<void> pumpLoggedIn(WidgetTester tester) async {
    await tester.pumpWidget(NavBasicsApp(session: session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();
  }

  Future<void> openFirstTask(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('T-001')));
    await tester.pumpAndSettle();
  }

  group('เส้นทางเข้าออกระบบ', () {
    testWidgets('ยังไม่ล็อกอินต้องเห็นหน้าเข้าสู่ระบบ', (tester) async {
      await tester.pumpWidget(NavBasicsApp(session: session));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('sign-in-button')), findsOneWidget);
      expect(find.byKey(const Key('bottom-nav')), findsNothing);
    });

    testWidgets('ล็อกอินแล้วเข้าหน้าหลัก และย้อนกลับเข้าหน้าเดิมไม่ได้', (
      tester,
    ) async {
      await tester.pumpWidget(NavBasicsApp(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sign-in-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('bottom-nav')), findsOneWidget);
      // pushReplacement เอาหน้าเข้าสู่ระบบออกจาก stack ไปแล้ว
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isFalse);
    });

    testWidgets('ออกจากระบบตอนอยู่ลึกในแอป ต้องไม่มีหน้าเก่าค้างอยู่', (
      tester,
    ) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);
      expect(find.text('งาน T-001'), findsOneWidget);

      // ย้อนกลับมาหน้าหลักแล้วออกจากระบบผ่านแผ่นตั้งค่า
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sign-out-button')));
      await tester.pumpAndSettle();

      expect(session.authenticated, isFalse);
      expect(find.byKey(const Key('sign-in-button')), findsOneWidget);
      expect(find.byKey(const Key('bottom-nav')), findsNothing);
      // ล้าง stack หมดแล้ว จึงย้อนกลับเข้าหน้าหลักไม่ได้อีก
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
          isFalse);
    });
  });

  group('ผลลัพธ์ที่ส่งกลับจากหน้ารายละเอียด', () {
    testWidgets('บันทึกแล้วรายการต้องอัปเดตและแจ้งผู้ใช้', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('quantity-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save-button')));
      await tester.pumpAndSettle();

      expect(find.text('13 ชิ้น'), findsOneWidget);
      expect(find.text('บันทึก T-001 แล้ว'), findsOneWidget);
    });

    testWidgets('กดย้อนกลับโดยไม่ได้แก้อะไร ต้องไม่มีข้อความใด ๆ', (
      tester,
    ) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('result-banner')), findsNothing);
      expect(find.text('12 ชิ้น'), findsOneWidget);
    });

    testWidgets('พักไว้ก่อน เก็บร่างไว้แต่ไม่ถือว่าเสร็จ', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('quantity-plus')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause-button')));
      await tester.pumpAndSettle();

      expect(find.text('13 ชิ้น'), findsOneWidget);
      expect(find.text('พัก T-001 ไว้ก่อน'), findsOneWidget);
      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    });
  });

  group('กันการปิดหน้าจอที่ยังแก้ค้างไว้', () {
    testWidgets('แก้แล้วกดย้อนกลับ ต้องถามก่อน และเลือกแก้ต่อได้', (
      tester,
    ) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('quantity-plus')));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('discard-keep')));
      await tester.pumpAndSettle();

      // ยังอยู่หน้าเดิม และค่าที่แก้ไว้ยังอยู่
      expect(find.text('งาน T-001'), findsOneWidget);
      expect(find.byKey(const Key('quantity-value')), findsOneWidget);
      expect(find.text('13 ชิ้น'), findsOneWidget);
    });

    testWidgets('ยืนยันทิ้ง ต้องออกจากหน้าและรายการไม่เปลี่ยน', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('quantity-plus')));
      await tester.pump();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('discard-confirm')));
      await tester.pumpAndSettle();

      expect(find.text('งาน T-001'), findsNothing);
      expect(find.text('12 ชิ้น'), findsOneWidget);
      expect(find.text('ยกเลิกการแก้ไข T-001'), findsOneWidget);
    });

    testWidgets('ยังไม่ได้แก้อะไร ปุ่มบันทึกต้องกดไม่ได้', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      final button = tester.widget<FilledButton>(
        find.byKey(const Key('save-button')),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('แผ่นเลือกและแผ่นตั้งค่า', () {
    testWidgets('เลือกพาเลทจากแผ่นแล้วค่าต้องเปลี่ยน', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('pallet-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('pallet-PAL-0103')));
      await tester.pumpAndSettle();

      expect(find.text('PAL-0103'), findsOneWidget);
    });

    testWidgets('ปิดแผ่นโดยไม่เลือก ค่าต้องไม่เปลี่ยน', (tester) async {
      await pumpLoggedIn(tester);
      await openFirstTask(tester);

      await tester.tap(find.byKey(const Key('pallet-field')));
      await tester.pumpAndSettle();
      // แตะนอกแผ่นเพื่อปิด
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('PAL-0101'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.byKey(const Key('save-button')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('แผ่นตั้งค่าที่แก้ค้างไว้ ต้องถามก่อนปิด', (tester) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scan-sound-switch')));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('discard-dialog')), findsOneWidget);
      expect(session.scanSound, isTrue);
    });

    testWidgets('บันทึกการตั้งค่าแล้วค่าใน session ต้องเปลี่ยน', (
      tester,
    ) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.byKey(const Key('settings-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scan-sound-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings-save')));
      await tester.pumpAndSettle();

      expect(session.scanSound, isFalse);
      expect(find.byKey(const Key('scan-sound-switch')), findsNothing);
    });
  });

  group('แถบล่าง', () {
    testWidgets('สลับแท็บแล้วเนื้อหาเปลี่ยน', (tester) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.text('ของฉัน'));
      await tester.pumpAndSettle();

      expect(find.text('ผู้ใช้: somchai'), findsOneWidget);
    });

    testWidgets('สลับแท็บแล้วแท็บเดิมยังอยู่ในต้นไม้ ไม่ถูกสร้างใหม่', (
      tester,
    ) async {
      await pumpLoggedIn(tester);

      await tester.tap(find.text('ประวัติ'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('history-tab')), findsOneWidget);
      // IndexedStack เก็บแท็บที่ไม่ได้เลือกไว้แบบ offstage — ยังอยู่ในต้นไม้
      // แต่ไม่ถูกวาด ตัวค้นหาจึงต้องบอกให้รวม offstage ด้วย
      expect(find.byKey(const Key('task-list')), findsNothing);
      expect(
        find.byKey(const Key('task-list'), skipOffstage: false),
        findsOneWidget,
      );
    });
  });
}
