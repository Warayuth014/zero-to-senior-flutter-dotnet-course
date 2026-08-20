/// อ่านเนื้อหาใน JWT
///
/// อ่านได้อย่างเดียว — ตรวจสอบว่า token ถูกต้องจริงไม่ได้ เพราะการตรวจ
/// ต้องใช้กุญแจที่มีแต่ server รู้ ฝั่งแอปจึงใช้ข้อมูลนี้เพื่อปรับหน้าจอเท่านั้น
/// ห้ามใช้ตัดสินสิทธิ์ (8.9)
library;

import 'dart:convert';

/// ชื่อ claim ที่ .NET ใช้เก็บ role โดยค่าตั้งต้น
///
/// ยาวแบบนี้เพราะเป็นมาตรฐานเก่าของ Microsoft — ถ้าฝั่งหลังบ้านตั้งค่าให้ใช้
/// ชื่อสั้นกว่านี้ได้ ควรขอให้เปลี่ยน แต่ต้องรองรับของเดิมไว้ด้วย
const String dotNetRoleClaim =
    'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';

const String dotNetNameClaim =
    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';

class JwtPayload {
  const JwtPayload(this.claims);

  final Map<String, dynamic> claims;

  /// เวลาหมดอายุ — `exp` เป็นจำนวนวินาทีนับจากปี 1970 ไม่ใช่ ISO-8601
  DateTime? get expiresAt {
    final exp = claims['exp'];
    if (exp is! num) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
  }

  String? get subject => _readString(claims['sub']);

  String? get username =>
      _readString(claims['name']) ??
      _readString(claims[dotNetNameClaim]) ??
      subject;

  /// role อาจมาเป็นข้อความเดี่ยวหรือรายการ ขึ้นกับว่าผู้ใช้มีกี่ role
  ///
  /// .NET ส่งข้อความเดี่ยวเมื่อมี role เดียว และส่ง array เมื่อมีหลาย role
  /// การรับได้ทั้งสองแบบจึงจำเป็น ไม่ใช่ความใจดี
  Set<String> get roles {
    final raw = claims['role'] ?? claims[dotNetRoleClaim] ?? claims['roles'];
    return switch (raw) {
      String value when value.trim().isNotEmpty => {value.trim()},
      List<Object?> values => {
        for (final value in values) ?_readString(value),
      },
      _ => const <String>{},
    };
  }

  static String? _readString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

/// แกะเนื้อหาส่วนกลางของ token ออกมา
///
/// คืน null เมื่อรูปแบบไม่ถูก — ไม่โยน เพราะการอ่าน token ไม่สำเร็จ
/// ไม่ควรทำให้ทั้งแอปหยุด สิ่งที่ตัดสินจริงคือ server (8.3)
JwtPayload? tryDecodeJwt(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;

  try {
    // base64url ใน JWT ตัด = ท้ายออก จึงต้องเติมกลับก่อนถอด
    final normalized = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final claims = jsonDecode(decoded);
    if (claims is! Map<String, dynamic>) return null;
    return JwtPayload(claims);
  } on FormatException {
    return null;
  }
}
