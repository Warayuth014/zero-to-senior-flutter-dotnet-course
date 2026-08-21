import 'package:flutter/widgets.dart';

import '../settings_lab/profile_store.dart' show SettingsStorage;
import 'app_messages.dart';

/// เจ้าของภาษาที่แอปใช้อยู่ และเป็นคนจำว่าผู้ใช้เลือกอะไรไว้
///
/// รับที่เก็บเข้ามาทาง constructor ตามกฎใน 9.8 ต่างจากของจริงใน
/// `wms_absolute_mobile` ที่เป็น singleton — 11.7 เทียบสองแบบนี้
class LanguageController extends ChangeNotifier {
  LanguageController(this.storage);

  static const String storageKey = 'app_language';

  final SettingsStorage storage;

  /// อังกฤษเป็นค่าเริ่มต้นของเครื่องที่เพิ่งติดตั้ง
  ///
  /// เลือกอังกฤษเพราะรหัสสินค้าและชื่อตำแหน่งที่เซิร์ฟเวอร์ส่งมาเป็น
  /// อังกฤษอยู่แล้ว หน้าจอที่ปนสองภาษาอ่านยากกว่าหน้าจอที่เป็นอังกฤษล้วน
  AppLanguage _language = AppLanguage.english;

  AppLanguage get language => _language;
  Locale get locale => _language.locale;
  bool get isThai => _language == AppLanguage.thai;

  Future<void> load() async {
    try {
      _language = AppLanguage.fromCode(await storage.read(storageKey));
    } catch (_) {
      // อ่านไม่ได้ก็ใช้ค่าเริ่มต้น ไม่ใช่เหตุให้เปิดแอปไม่ได้ (8.5)
      _language = AppLanguage.english;
    }
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (_language == value) return;
    _language = value;

    // ประกาศก่อนเขียนลงเครื่อง เพราะหน้าจอต้องเปลี่ยนทันทีที่กด
    // ไม่ใช่รอให้เขียนดิสก์เสร็จ
    notifyListeners();

    try {
      await storage.write(storageKey, value.code);
    } catch (_) {
      // เขียนไม่ได้ก็ยังสลับได้ในรอบนี้ แลกกับว่าปิดแอปแล้วกลับเป็นค่าเดิม
    }
  }

  Future<void> toggle() =>
      setLanguage(isThai ? AppLanguage.english : AppLanguage.thai);

  /// อ่านข้อความหนึ่งก้อนเป็นภาษาที่ใช้อยู่
  String text(Message message) => message.of(_language);

  /// อ่านข้อความที่ต้องเติมค่า
  String text1<T>(Message1<T> message, T value) =>
      message.of(_language, value);
}

/// ส่ง [LanguageController] ลงไปให้ทั้งต้นไม้ของ widget
///
/// ใช้ [InheritedNotifier] ซึ่งทำสองอย่างพร้อมกัน คือส่งของลงไปโดยไม่ต้อง
/// ต่อ parameter เป็นทอด ๆ และสั่งให้ widget ที่อ่านค่านี้วาดใหม่เมื่อ
/// controller ประกาศว่ามีอะไรเปลี่ยน (9.8)
class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LanguageScope>();
    assert(scope != null, 'ไม่พบ LanguageScope เหนือ widget นี้');
    return scope!.notifier!;
  }
}

/// ทางลัดที่ทำให้โค้ดในจออ่านง่าย
///
/// เขียน `context.t(AppText.signIn)` แทน
/// `LanguageScope.of(context).text(AppText.signIn)`
extension LanguageContext on BuildContext {
  String t(Message message) => LanguageScope.of(this).text(message);
  String t1<T>(Message1<T> message, T value) =>
      LanguageScope.of(this).text1(message, value);
  AppLanguage get language => LanguageScope.of(this).language;
}
