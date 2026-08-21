import 'package:flutter/material.dart';

import 'pda_tokens.dart';

/// ประกอบ token ทั้งหมดเป็น [ThemeData] ชุดเดียว
///
/// ทุกจอในแอปอ่านค่าจากที่นี่ผ่าน `Theme.of(context)` แทนที่จะเขียนสีและ
/// ขนาดลงไปในจอตรง ๆ — เปลี่ยนธีมทั้งแอปจึงแก้ไฟล์เดียว (11.1)
ThemeData buildPdaTheme() {
  const scheme = ColorScheme.light(
    primary: PdaColors.primary,
    onPrimary: Colors.white,
    primaryContainer: PdaColors.primarySoft,
    onPrimaryContainer: PdaColors.primaryDark,
    error: PdaColors.danger,
    onError: Colors.white,
    surface: PdaColors.surface,
    onSurface: PdaColors.heading,
    outline: PdaColors.border,
    outlineVariant: PdaColors.divider,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: PdaColors.pageBg,

    // ปุ่มบน PDA ต้องกดโดนแม้ใส่ถุงมือ จึงไม่ย่อขนาดพื้นที่กด
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: PdaColors.heading,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: PdaColors.heading,
        height: 1.3,
      ),
      // height 1.4 ไม่ใช่ค่าปริยาย 1.0 เพราะสระบนล่างของไทยต้องการที่ (11.4)
      bodyLarge: TextStyle(fontSize: 14.5, color: PdaColors.heading, height: 1.4),
      bodyMedium: TextStyle(fontSize: 13.5, color: PdaColors.heading, height: 1.4),
      bodySmall: TextStyle(fontSize: 12.5, color: PdaColors.subtitle, height: 1.35),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: PdaColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: PdaColors.border,
        disabledForegroundColor: PdaColors.subtitle,
        minimumSize: const Size.fromHeight(PdaMetrics.primaryButtonHeight),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PdaMetrics.controlRadius),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        foregroundColor: PdaColors.primaryDark,
        side: const BorderSide(color: PdaColors.border, width: 1.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PdaMetrics.controlRadius),
        ),
      ),
    ),

    cardTheme: CardThemeData(
      color: PdaColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PdaMetrics.cardRadius),
        side: const BorderSide(color: PdaColors.border),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PdaColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
      border: _fieldBorder(PdaColors.border),
      enabledBorder: _fieldBorder(PdaColors.border),
      focusedBorder: _fieldBorder(PdaColors.primary, width: 1.6),
      errorBorder: _fieldBorder(PdaColors.danger),
      focusedErrorBorder: _fieldBorder(PdaColors.danger, width: 1.6),
    ),

    dividerTheme: const DividerThemeData(
      color: PdaColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}

OutlineInputBorder _fieldBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
