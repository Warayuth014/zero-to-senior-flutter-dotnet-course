/// ข้อความทุกก้อนที่ผู้ใช้เห็น รวมอยู่ที่เดียว
///
/// เขียนเป็นคลาสที่มี getter แทนที่จะเรียก `tr('English', 'ไทย')` กระจาย
/// ทั่วโค้ด เพราะแบบหลังทำให้สามอย่างนี้เป็นไปไม่ได้ (11.7)
///   1. รู้ว่าแอปมีข้อความทั้งหมดกี่ก้อน
///   2. หาว่าก้อนไหนยังไม่ได้แปล
///   3. ให้คนที่ไม่ใช่โปรแกรมเมอร์ช่วยตรวจคำ
library;

import 'package:flutter/widgets.dart';

/// ภาษาที่แอปรองรับ
enum AppLanguage {
  english('en', 'EN'),
  thai('th', 'TH');

  const AppLanguage(this.code, this.label);

  /// รหัสภาษาตามมาตรฐาน ใช้กับ [Locale] และการจัดรูปแบบวันที่
  final String code;

  /// ป้ายสั้นที่แสดงบนปุ่มสลับภาษา
  final String label;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) =>
      code == 'th' ? AppLanguage.thai : AppLanguage.english;
}

/// คู่ข้อความอังกฤษ–ไทยหนึ่งก้อน
///
/// เป็นคลาสแทนที่จะเป็น `Map<String, String>` เพื่อให้ลืมภาษาใดภาษาหนึ่ง
/// ไม่ได้ — คอมไพเลอร์บังคับให้ใส่ครบทั้งสองตัวตั้งแต่ตอนสร้าง
class Message {
  const Message(this.en, this.th);

  final String en;
  final String th;

  String of(AppLanguage language) =>
      language == AppLanguage.thai ? th : en;
}

/// ข้อความที่ต้องเติมค่าลงไป
///
/// แยกชนิดจาก [Message] เพราะเรียกใช้ไม่เหมือนกัน และเพราะการเติมค่าด้วย
/// การต่อสตริงเองทำให้ลำดับคำผิดในบางภาษา
class Message1<T> {
  const Message1(this._en, this._th);

  final String Function(T) _en;
  final String Function(T) _th;

  String of(AppLanguage language, T value) =>
      language == AppLanguage.thai ? _th(value) : _en(value);
}

/// รายการข้อความทั้งหมดของแอป
///
/// ทุกฟิลด์เป็น `static const` ทำให้ค้นด้วย IDE ได้ว่าข้อความก้อนไหนถูกใช้
/// ที่ไหนบ้าง และลบข้อความที่ไม่มีใครใช้แล้วได้อย่างมั่นใจ
class AppText {
  const AppText._();

  // ---------------------------------------------------------------- ทั่วไป
  static const Message appTitle = Message('ACETEC WMS', 'ACETEC WMS');
  static const Message retry = Message('Retry', 'ลองใหม่');
  static const Message cancel = Message('Cancel', 'ยกเลิก');
  static const Message confirm = Message('Confirm', 'ยืนยัน');
  static const Message save = Message('Save', 'บันทึก');

  // ------------------------------------------------------------ เข้าสู่ระบบ
  static const Message signIn = Message('Sign in', 'เข้าสู่ระบบ');
  static const Message signOut = Message('Sign out', 'ออกจากระบบ');
  static const Message username = Message('Username', 'ชื่อผู้ใช้');
  static const Message password = Message('Password', 'รหัสผ่าน');
  static const Message wrongCredentials = Message(
    'Username or password is incorrect',
    'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
  );

  // ---------------------------------------------------------------- คลัง
  static const Message pallets = Message('Pallets', 'พาเลท');
  static const Message noPallets = Message(
    'No pallets in this zone',
    'ไม่มีพาเลทในโซนนี้',
  );
  static const Message scanPallet = Message('Scan pallet', 'สแกนพาเลท');

  // ------------------------------------------------------------ เชื่อมต่อ
  static const Message offline = Message(
    'Cannot reach the server',
    'ติดต่อเซิร์ฟเวอร์ไม่ได้',
  );
  static const Message checking = Message('Checking…', 'กำลังตรวจสอบ…');

  // ---------------------------------------------------- ข้อความที่มีค่าแทรก
  //
  // สังเกตว่าลำดับคำในสองภาษาไม่เหมือนกัน — ภาษาอังกฤษเอาจำนวนขึ้นก่อน
  // ส่วนไทยเอาคำนามขึ้นก่อน ถ้าต่อสตริงเองด้วย '$count ' + tr('items','รายการ')
  // จะได้ภาษาไทยที่อ่านแปลก ๆ ตลอดไป
  static const Message1<int> palletCount = Message1(
    _palletCountEn,
    _palletCountTh,
  );

  static const Message1<String> heldBy = Message1(
    _heldByEn,
    _heldByTh,
  );

  /// ข้อความทุกก้อน ใช้ในเทสต์เพื่อตรวจว่าไม่มีก้อนไหนตกหล่น (11.8)
  static const List<Message> all = [
    appTitle,
    retry,
    cancel,
    confirm,
    save,
    signIn,
    signOut,
    username,
    password,
    wrongCredentials,
    pallets,
    noPallets,
    scanPallet,
    offline,
    checking,
  ];
}

// ภาษาอังกฤษต้องเลือกรูปเอกพจน์/พหูพจน์ ส่วนภาษาไทยไม่ต้อง
String _palletCountEn(int count) =>
    count == 1 ? '1 pallet' : '$count pallets';
String _palletCountTh(int count) => 'พาเลท $count ใบ';

String _heldByEn(String name) => 'Held by $name';
String _heldByTh(String name) => '$name ล็อกไว้อยู่';
