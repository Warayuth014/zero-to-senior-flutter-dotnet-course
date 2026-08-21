/// ค่าคงที่ของหน้าตาแอป ที่ทุกจอต้องใช้ร่วมกัน
///
/// เรียกว่า design token — ตั้งชื่อตาม**หน้าที่** ไม่ใช่ตามสี เพื่อให้
/// เปลี่ยนสีทีหลังได้โดยไม่ต้องเปลี่ยนชื่อไปทั้งโปรเจกต์ (11.3)
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

class PdaColors {
  const PdaColors._();

  // สีของแบรนด์
  static const Color brand = Color(0xFF2468AE);
  static const Color primary = Color(0xFF2E73B9);
  static const Color primaryDark = Color(0xFF174D80);
  static const Color primarySoft = Color(0xFFE9F3FF);

  // สีของตัวอักษร
  static const Color heading = Color(0xFF102A43);
  static const Color subtitle = Color(0xFF60758A);

  // สีของเส้นและพื้น
  static const Color border = Color(0xFFD9E5EF);
  static const Color divider = Color(0xFFE7EEF5);
  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF6F9FC);
  static const Color pageBg = Color(0xFFEDF3F8);

  /// สีที่บอกผลของการกระทำ
  ///
  /// ในคลังที่มีเสียงดัง ผู้ใช้ตัดสินจากสีก่อนอ่านข้อความ สามสีนี้จึงต้อง
  /// แยกออกจากกันชัดแม้มองแวบเดียว และต้องไม่พึ่งสีอย่างเดียว (11.1)
  ///
  /// ค่าที่ใช้ตรงนี้ถูกทำให้เข้มกว่าสีแบรนด์ดั้งเดิม เพราะเทสต์ความต่างสี
  /// จับได้ว่าตัวอักษรขาวบนสีเดิมอ่านไม่ออกตามเกณฑ์ (11.2)
  static const Color danger = Color(0xFFB3261E);
  static const Color success = Color(0xFF157C4C);
  static const Color warning = Color(0xFFD78A13);

  /// สีตัวอักษรที่คู่กับพื้นสีสถานะ
  ///
  /// ต้องประกาศคู่กันเสมอ ไม่ใช่สมมติว่าใช้สีขาวได้ทุกอัน — สีเหลืองส้ม
  /// สว่างเกินกว่าจะรองรับตัวอักษรขาว ไม่ว่าจะปรับเฉดอย่างไร นอกจากจะ
  /// ทำให้เข้มจนไม่เหลือความเป็นสีเหลืองส้ม (11.2)
  static const Color onDanger = Colors.white;
  static const Color onSuccess = Colors.white;
  static const Color onWarning = heading;
}

class PdaMetrics {
  const PdaMetrics._();

  static const double screenPadding = 12;
  static const double cardRadius = 16;
  static const double controlRadius = 14;

  /// ขนาดต่ำสุดของสิ่งที่กดได้
  ///
  /// 48 มาจากแนวทางของ Material แต่บน PDA มีเหตุผลเพิ่มคือผู้ใช้ใส่ถุงมือ
  /// และกดขณะเดิน ปุ่มหลักในแอปนี้จึงสูง 54 ไม่ใช่ 48 (11.1)
  static const double minTapTarget = 48;
  static const double primaryButtonHeight = 54;
}

/// ความสว่างสัมพัทธ์ตามสูตรของ WCAG
///
/// ไม่ใช่ค่าเฉลี่ยของ R G B ธรรมดา — ตาคนไวต่อสีเขียวมากที่สุดและไวต่อ
/// สีน้ำเงินน้อยที่สุด สูตรนี้จึงถ่วงน้ำหนักต่างกัน
double relativeLuminance(Color color) {
  double channel(double value) =>
      value <= 0.03928 ? value / 12.92 : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

/// อัตราส่วนความต่างระหว่างสองสี ตั้งแต่ 1 (เหมือนกัน) ถึง 21 (ดำบนขาว)
///
/// ใช้ตรวจว่าตัวอักษรอ่านออกไหม เกณฑ์ของ WCAG คือ
///   4.5 สำหรับตัวอักษรปกติ
///   3.0 สำหรับตัวใหญ่ (18pt ขึ้นไป หรือ 14pt ตัวหนา)
///
/// ในคลังที่มีแสงจ้าส่องจากหลังคา ค่าจริงที่ใช้งานได้ควรสูงกว่านี้ (11.2)
double contrastRatio(Color foreground, Color background) {
  final a = relativeLuminance(foreground);
  final b = relativeLuminance(background);
  final lighter = math.max(a, b);
  final darker = math.min(a, b);
  return (lighter + 0.05) / (darker + 0.05);
}
