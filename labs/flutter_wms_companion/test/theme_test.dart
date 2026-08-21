import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/settings_lab/profile_store.dart';
import 'package:flutter_wms_companion/theme_lab/app_messages.dart';
import 'package:flutter_wms_companion/theme_lab/language_controller.dart';
import 'package:flutter_wms_companion/theme_lab/pda_shell.dart';
import 'package:flutter_wms_companion/theme_lab/pda_theme.dart';
import 'package:flutter_wms_companion/theme_lab/pda_tokens.dart';
import 'package:flutter_wms_companion/theme_lab/wms_formats.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  // intl ต้องโหลดข้อมูลของแต่ละภาษาก่อนใช้ ไม่งั้นจะได้แต่ภาษาอังกฤษ
  setUpAll(() => initializeDateFormatting());

  group('design token', () {
    test('ตัวอักษรบนพื้นต้องผ่านเกณฑ์ความต่างของ WCAG', () {
      // 4.5 คือเกณฑ์สำหรับตัวอักษรขนาดปกติ — คลังที่มีแสงจ้าต้องการมากกว่านี้
      // แต่ต่ำกว่านี้คืออ่านไม่ออกแน่นอน
      final pairs = <String, (Color, Color)>{
        'หัวข้อบนพื้นขาว': (PdaColors.heading, PdaColors.surface),
        'หัวข้อบนพื้นหน้า': (PdaColors.heading, PdaColors.pageBg),
        'หัวข้อบนพื้นจาง': (PdaColors.heading, PdaColors.surfaceMuted),
        'ตัวอักษรขาวบนปุ่มหลัก': (Colors.white, PdaColors.primary),
      };

      for (final entry in pairs.entries) {
        final (foreground, background) = entry.value;
        expect(
          contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: '${entry.key} ความต่างไม่พอ',
        );
      }
    });

    test('ข้อความรองผ่านเกณฑ์ของตัวอักษรขนาดใหญ่เป็นอย่างน้อย', () {
      // subtitle ใช้กับ bodySmall 12.5 ซึ่งไม่นับเป็นตัวใหญ่ จึงควรถึง 4.5
      // เทสต์นี้บันทึกค่าจริงไว้ ถ้าใครแก้สีให้จางลง เทสต์จะฟ้อง
      expect(
        contrastRatio(PdaColors.subtitle, PdaColors.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('ป้ายสถานะทุกอันอ่านออก โดยใช้สีตัวอักษรที่จับคู่ไว้', () {
      // ป้ายสถานะเป็นตัวอักษรขนาดปกติ จึงต้องถึง 4.5 ไม่ใช่ 3.0
      final pairs = <String, (Color, Color)>{
        'สำเร็จ': (PdaColors.onSuccess, PdaColors.success),
        'ล้มเหลว': (PdaColors.onDanger, PdaColors.danger),
        'เตือน': (PdaColors.onWarning, PdaColors.warning),
      };

      for (final entry in pairs.entries) {
        final (foreground, background) = entry.value;
        expect(
          contrastRatio(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: 'ป้าย${entry.key}อ่านไม่ออก',
        );
      }
    });

    test('ตัวอักษรขาวใช้กับสีเหลืองส้มไม่ได้ ไม่ว่าจะอยากใช้แค่ไหน', () {
      // เทสต์นี้บันทึกข้อจำกัดทางฟิสิกส์ไว้ ไม่ใช่บันทึกบั๊ก — เพื่อให้คนที่
      // มาเปลี่ยน onWarning เป็นสีขาวในอนาคต เห็นทันทีว่าทำไมถึงทำไม่ได้
      expect(contrastRatio(Colors.white, PdaColors.warning), lessThan(4.5));
    });

    test('ปุ่มหลักสูงพอสำหรับมือที่ใส่ถุงมือ', () {
      expect(
        PdaMetrics.primaryButtonHeight,
        greaterThanOrEqualTo(PdaMetrics.minTapTarget),
      );
    });
  });

  group('ธีม', () {
    test('ปุ่มหลักได้ความสูงมาจาก token ไม่ใช่ค่าที่เขียนซ้ำ', () {
      final theme = buildPdaTheme();
      final style = theme.filledButtonTheme.style!;
      final size = style.minimumSize!.resolve({});

      expect(size!.height, PdaMetrics.primaryButtonHeight);
    });

    test('ตัวอักษรเนื้อความมี height เผื่อสระไทย', () {
      final theme = buildPdaTheme();
      // ค่าปริยายคือ null ซึ่งแปลว่า 1.0 และทำให้สระบนล่างชนกัน
      expect(theme.textTheme.bodyMedium!.height, greaterThanOrEqualTo(1.3));
      expect(theme.textTheme.bodyLarge!.height, greaterThanOrEqualTo(1.3));
    });

    test('พื้นที่กดไม่ถูกย่อ', () {
      expect(
        buildPdaTheme().materialTapTargetSize,
        MaterialTapTargetSize.padded,
      );
    });
  });

  group('รายการข้อความ', () {
    test('ทุกก้อนมีทั้งสองภาษา และไม่มีก้อนไหนว่าง', () {
      for (final message in AppText.all) {
        expect(message.en.trim(), isNotEmpty, reason: 'ภาษาอังกฤษว่าง');
        expect(message.th.trim(), isNotEmpty, reason: 'ภาษาไทยว่าง');
      }
    });

    test('ก้อนที่ยังไม่ได้แปล ต้องถูกจับได้', () {
      // ข้อความไทยที่เหมือนอังกฤษเป๊ะ มักแปลว่าลืมแปล — ยกเว้นชื่อเฉพาะ
      const properNouns = {'ACETEC WMS'};

      final untranslated = [
        for (final message in AppText.all)
          if (message.en == message.th && !properNouns.contains(message.en))
            message.en,
      ];

      expect(untranslated, isEmpty, reason: 'ยังไม่ได้แปล: $untranslated');
    });

    test('เลือกภาษาถูกตัว', () {
      expect(AppText.signIn.of(AppLanguage.english), 'Sign in');
      expect(AppText.signIn.of(AppLanguage.thai), 'เข้าสู่ระบบ');
    });

    test('ข้อความที่มีค่าแทรก เรียงคำตามภาษาของตัวเอง', () {
      // อังกฤษเอาจำนวนขึ้นก่อน ไทยเอาคำนามขึ้นก่อน
      expect(AppText.palletCount.of(AppLanguage.english, 12), '12 pallets');
      expect(AppText.palletCount.of(AppLanguage.thai, 12), 'พาเลท 12 ใบ');

      expect(AppText.heldBy.of(AppLanguage.english, 'สมชาย'), 'Held by สมชาย');
      expect(AppText.heldBy.of(AppLanguage.thai, 'สมชาย'), 'สมชาย ล็อกไว้อยู่');
    });

    test('ภาษาอังกฤษเลือกรูปเอกพจน์ถูก ส่วนไทยไม่ต้อง', () {
      expect(AppText.palletCount.of(AppLanguage.english, 1), '1 pallet');
      expect(AppText.palletCount.of(AppLanguage.thai, 1), 'พาเลท 1 ใบ');
    });
  });

  group('LanguageController', () {
    late InMemorySettingsStorage storage;

    setUp(() => storage = InMemorySettingsStorage());

    test('เครื่องที่เพิ่งติดตั้งได้ภาษาอังกฤษ', () async {
      final controller = LanguageController(storage);
      await controller.load();

      expect(controller.language, AppLanguage.english);
    });

    test('เลือกแล้วจำได้ข้ามการปิดแอป', () async {
      final first = LanguageController(storage);
      await first.load();
      await first.setLanguage(AppLanguage.thai);

      final second = LanguageController(storage);
      await second.load();
      expect(second.language, AppLanguage.thai);
    });

    test('สลับแล้วประกาศให้หน้าจอวาดใหม่', () async {
      final controller = LanguageController(storage);
      await controller.load();
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.toggle();
      expect(notified, 1);
      expect(controller.isThai, isTrue);
    });

    test('เลือกภาษาเดิมซ้ำ ต้องไม่ประกาศ', () async {
      final controller = LanguageController(storage);
      await controller.load();
      var notified = 0;
      controller.addListener(() => notified++);

      await controller.setLanguage(AppLanguage.english);
      expect(notified, 0);
    });

    test('เขียนลงเครื่องไม่ได้ ต้องยังสลับได้ในรอบนี้', () async {
      final controller = LanguageController(storage);
      await controller.load();
      storage.failOnWrite = true;

      await controller.setLanguage(AppLanguage.thai);
      expect(controller.isThai, isTrue);
    });

    test('ค่าที่เก็บไว้อ่านไม่รู้เรื่อง ให้ตกเป็นอังกฤษ', () async {
      final controller = LanguageController(
        InMemorySettingsStorage(seed: {LanguageController.storageKey: 'zz'}),
      );
      await controller.load();

      expect(controller.language, AppLanguage.english);
    });
  });

  group('การจัดรูปแบบ', () {
    test('จำนวนมีตัวคั่นหลักพัน', () {
      expect(formatCount(12000, AppLanguage.english), '12,000');
      expect(formatCount(12000, AppLanguage.thai), '12,000');
    });

    test('จำนวนที่มีทศนิยมไม่ตัดศูนย์ท้ายทิ้ง', () {
      expect(formatQuantity(12, AppLanguage.english), '12.00');
      expect(formatQuantity(12.5, AppLanguage.english), '12.50');
      expect(formatQuantity(1234.5, AppLanguage.thai), '1,234.50');
    });

    test('เวลาแปลงจาก UTC เป็นเวลาเครื่องก่อนแสดง', () {
      final utc = DateTime.utc(2026, 8, 21, 7, 32);
      final expected = utc.toLocal();
      final shown = formatTime(utc, AppLanguage.english);

      expect(shown, '${expected.hour.toString().padLeft(2, '0')}:'
          '${expected.minute.toString().padLeft(2, '0')}');
    });

    test('วันที่ภาษาไทยใช้ปี พ.ศ.', () {
      final utc = DateTime.utc(2026, 3, 15, 4, 0);
      final local = utc.toLocal();
      final thai = formatDate(utc, AppLanguage.thai);

      // 2026 + 543 = 2569 → แสดงสองหลักท้ายคือ 69
      expect(thai, contains(((local.year + 543) % 100).toString()));
      // และต้องไม่มี ค.ศ. หลุดออกมา
      expect(thai, isNot(contains('26')));
    });

    test('วันที่ภาษาอังกฤษใช้ ค.ศ.', () {
      final utc = DateTime.utc(2026, 3, 15, 4, 0);
      expect(formatDate(utc, AppLanguage.english), contains('26'));
    });

    test('เวลาที่ผ่านมา เลือกหน่วยตามช่วง', () {
      final now = DateTime.utc(2026, 8, 21, 12, 0);

      expect(
        formatElapsed(now.subtract(const Duration(seconds: 30)),
            AppLanguage.thai, now: now),
        'เมื่อครู่',
      );
      expect(
        formatElapsed(now.subtract(const Duration(minutes: 3)),
            AppLanguage.thai, now: now),
        '3 นาทีที่แล้ว',
      );
      expect(
        formatElapsed(now.subtract(const Duration(hours: 5)),
            AppLanguage.english, now: now),
        '5 hr ago',
      );
    });

    test('เกินหนึ่งวันแล้ว แสดงวันที่แทน', () {
      final now = DateTime.utc(2026, 8, 21, 12, 0);
      final old = now.subtract(const Duration(days: 3));

      expect(
        formatElapsed(old, AppLanguage.english, now: now),
        formatDate(old, AppLanguage.english),
      );
    });

    test('เวลาในอนาคตต้องไม่กลายเป็นค่าติดลบประหลาด', () {
      // นาฬิกาเครื่องกับเซิร์ฟเวอร์ไม่ตรงกันเป็นเรื่องปกติ (8.3)
      final now = DateTime.utc(2026, 8, 21, 12, 0);
      final future = now.add(const Duration(minutes: 2));

      expect(formatElapsed(future, AppLanguage.thai, now: now), 'เมื่อครู่');
    });
  });

  group('แอปสองภาษา', () {
    Future<LanguageController> pumpApp(WidgetTester tester) async {
      final controller = LanguageController(InMemorySettingsStorage());
      await controller.load();
      await tester.pumpWidget(PdaApp(controller: controller));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('เปิดมาเป็นภาษาอังกฤษ', (tester) async {
      await pumpApp(tester);

      expect(find.text('Pallets'), findsOneWidget);
      expect(find.text('12 pallets'), findsOneWidget);
      expect(find.text('Scan pallet'), findsOneWidget);
    });

    testWidgets('กดปุ่มเดียวแล้วทั้งจอเปลี่ยนภาษา', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('language-button')));
      await tester.pumpAndSettle();

      expect(find.text('พาเลท'), findsOneWidget);
      expect(find.text('พาเลท 12 ใบ'), findsOneWidget);
      expect(find.text('สแกนพาเลท'), findsOneWidget);
      expect(find.text('Pallets'), findsNothing);
    });

    testWidgets('ปุ่มแสดงภาษาที่ใช้อยู่ ไม่ใช่ภาษาที่จะสลับไป', (tester) async {
      await pumpApp(tester);
      expect(find.text('EN'), findsOneWidget);

      await tester.tap(find.byKey(const Key('language-button')));
      await tester.pumpAndSettle();
      expect(find.text('TH'), findsOneWidget);
    });

    testWidgets('MaterialApp ได้ locale ตามที่เลือก', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byKey(const Key('language-button')));
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      // ถ้าไม่ส่ง locale ลงไป widget สำเร็จรูปของ Material จะยังเป็นอังกฤษ
      expect(app.locale, const Locale('th'));
    });

    testWidgets('ปุ่มสลับภาษากดโดนแม้ใส่ถุงมือ', (tester) async {
      await pumpApp(tester);

      final size = tester.getSize(find.byKey(const Key('language-button')));
      expect(size.height, greaterThanOrEqualTo(PdaMetrics.minTapTarget));
      expect(size.width, greaterThanOrEqualTo(PdaMetrics.minTapTarget));
    });

    testWidgets('ปุ่มหลักสูงตามที่ธีมกำหนด', (tester) async {
      await pumpApp(tester);

      final size = tester.getSize(find.byKey(const Key('scan-button')));
      expect(size.height, PdaMetrics.primaryButtonHeight);
    });
  });
}
