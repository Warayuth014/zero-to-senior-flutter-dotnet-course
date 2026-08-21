import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_messages.dart';
import 'language_controller.dart';
import 'pda_theme.dart';
import 'pda_tokens.dart';

/// แอปตัวอย่างสองภาษาของ Part 11
class PdaApp extends StatelessWidget {
  const PdaApp({super.key, required this.controller});

  final LanguageController controller;

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: controller,
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildPdaTheme(),

        // locale บอก Flutter ว่าจะใช้ภาษาไหนกับข้อความของ widget สำเร็จรูป
        // เช่นปุ่ม OK/Cancel ในตัวเลือกวันที่ และคำว่า "Search" ใน SearchBar
        locale: controller.locale,
        supportedLocales: const [Locale('en'), Locale('th')],

        // สาม delegate นี้มาจาก flutter_localizations ไม่ได้แปลข้อความของเรา
        // แต่แปลข้อความที่ฝังอยู่ใน Material, Cupertino และ widget พื้นฐาน
        // ถ้าไม่ใส่ ตัวเลือกวันที่จะขึ้นภาษาอังกฤษแม้ผู้ใช้เลือกไทย (11.6)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        home: const PdaHomeScreen(),
      ),
    ),
  );
}

class PdaHomeScreen extends StatelessWidget {
  const PdaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      backgroundColor: PdaColors.brand,
      foregroundColor: Colors.white,
      title: Text(context.t(AppText.appTitle)),
      actions: const [LanguageButton()],
    ),
    body: Padding(
      padding: const EdgeInsets.all(PdaMetrics.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.t(AppText.pallets),
            key: const Key('section-title'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            context.t1(AppText.palletCount, 12),
            key: const Key('pallet-count'),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('scan-button'),
            onPressed: () {},
            child: Text(context.t(AppText.scanPallet)),
          ),
        ],
      ),
    ),
  );
}

/// ปุ่มสลับภาษา
///
/// แสดงป้ายของภาษา**ที่ใช้อยู่** ไม่ใช่ภาษาที่จะสลับไป — ผู้ใช้ที่มองแวบเดียว
/// ต้องตอบได้ว่า "ตอนนี้ภาษาอะไร" ซึ่งเป็นคำถามที่ถูกถามบ่อยกว่า
/// "กดแล้วจะได้ภาษาอะไร" (11.7)
class LanguageButton extends StatelessWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Tooltip(
        // ข้อความบอกผลของการกด ซึ่งต่างจากป้ายบนปุ่ม
        message: controller.isThai ? 'Switch to English' : 'เปลี่ยนเป็นภาษาไทย',
        child: TextButton(
          key: const Key('language-button'),
          onPressed: controller.toggle,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            minimumSize: const Size(PdaMetrics.minTapTarget, PdaMetrics.minTapTarget),
          ),
          child: Text(
            controller.language.label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
