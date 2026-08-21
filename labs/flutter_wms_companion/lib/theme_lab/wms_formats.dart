/// การจัดรูปแบบวันที่และตัวเลขให้ตรงกับภาษาที่ผู้ใช้เลือก
///
/// รวมไว้ที่เดียวเพราะกฎเหล่านี้ต้องเหมือนกันทุกจอ และเพราะกฎบางข้อ
/// (เช่นปี พ.ศ.) ผิดง่ายมากถ้าปล่อยให้แต่ละจอทำเอง (11.9)
library;

import 'package:intl/intl.dart';

import 'app_messages.dart';

/// จำนวนชิ้น
///
/// ใส่ตัวคั่นหลักพันเสมอ เพราะ 12000 กับ 1200 บนจอเล็กที่มองแวบเดียว
/// แยกยาก แต่ 12,000 กับ 1,200 แยกออกทันที
String formatCount(num value, AppLanguage language) =>
    NumberFormat.decimalPattern(language.code).format(value);

/// จำนวนที่มีทศนิยม เช่นน้ำหนักหรือความยาว
///
/// บังคับให้แสดงทศนิยมตามที่กำหนดเสมอ ไม่ตัดศูนย์ท้ายทิ้ง — 12.0 กับ 12
/// สื่อความแม่นยำต่างกันในใบรับของ
String formatQuantity(num value, AppLanguage language, {int decimals = 2}) {
  final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
  return NumberFormat(pattern, language.code).format(value);
}

/// เวลาที่แสดงบนหน้าจอ
///
/// รับ [DateTime] ที่เป็น UTC ตามกฎใน 6.9 แล้วแปลงเป็นเวลาท้องถิ่นของ
/// เครื่องก่อนแสดง — เก็บเป็น UTC แสดงเป็นท้องถิ่น เป็นกฎที่ห้ามสลับ
String formatTime(DateTime utc, AppLanguage language) =>
    DateFormat.Hm(language.code).format(utc.toLocal());

/// วันที่แบบสั้น สำหรับตารางและรายการ
String formatDate(DateTime utc, AppLanguage language) {
  final local = utc.toLocal();
  if (language == AppLanguage.thai) {
    // ไทยใช้ พ.ศ. ซึ่ง intl ไม่ได้แปลงให้ ต้องบวก 543 เอง แล้วใส่ลงไป
    // เป็นข้อความ ไม่ใช่ปล่อยให้ DateFormat อ่านปีจาก DateTime
    final buddhistYear = local.year + 543;
    final day = local.day.toString().padLeft(2, '0');
    final month = DateFormat.MMM('th').format(local);
    return '$day $month ${buddhistYear % 100}';
  }
  return DateFormat('dd MMM yy', language.code).format(local);
}

/// วันที่พร้อมเวลา สำหรับหน้ารายละเอียด
String formatDateTime(DateTime utc, AppLanguage language) =>
    '${formatDate(utc, language)} ${formatTime(utc, language)}';

/// เวลาที่ผ่านมาแล้ว เช่น "3 นาทีที่แล้ว"
///
/// ใช้กับสิ่งที่เพิ่งเกิด ผู้ใช้อ่าน "3 นาทีที่แล้ว" ได้เร็วกว่า "14:32"
/// เพราะไม่ต้องเอาไปลบกับเวลาปัจจุบันในหัว
///
/// [now] รับเข้ามาได้เพื่อให้เทสต์คุมเวลาได้ (9.8)
String formatElapsed(DateTime utc, AppLanguage language, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).toUtc().difference(utc.toUtc());
  final thai = language == AppLanguage.thai;

  if (elapsed.isNegative || elapsed.inSeconds < 60) {
    return thai ? 'เมื่อครู่' : 'just now';
  }
  if (elapsed.inMinutes < 60) {
    final n = elapsed.inMinutes;
    return thai ? '$n นาทีที่แล้ว' : '$n min ago';
  }
  if (elapsed.inHours < 24) {
    final n = elapsed.inHours;
    return thai ? '$n ชั่วโมงที่แล้ว' : '$n hr ago';
  }
  // เกินหนึ่งวันแล้ว เวลาที่ผ่านมาไม่มีประโยชน์เท่าวันที่จริง
  return formatDate(utc, language);
}
