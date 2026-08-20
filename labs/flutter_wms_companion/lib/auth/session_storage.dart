import 'dart:convert';

import 'auth_session.dart';

/// ที่เก็บ session ข้ามการปิดแอป
///
/// เป็นสัญญา ไม่ใช่คลาสจริง เพราะที่เก็บจริงต่างกันตามแพลตฟอร์ม
/// และเทสต์ต้องใช้ของปลอมที่ควบคุมได้ (8.10)
abstract interface class SessionStorage {
  Future<AuthSession?> read();
  Future<void> write(AuthSession session);
  Future<void> clear();
}

/// ข้อผิดพลาดของที่เก็บ — แยกจากข้อผิดพลาดของเครือข่าย
class SessionStorageException implements Exception {
  const SessionStorageException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// รุ่นของโครงข้อมูลที่เก็บ
///
/// ต้องมีตั้งแต่วันแรก เพราะวันที่โครงเปลี่ยน ต้องแยกให้ออกระหว่าง
/// "ข้อมูลเสีย" กับ "ข้อมูลของรุ่นเก่า" ซึ่งต้องจัดการคนละแบบ
const int sessionSchemaVersion = 1;

/// แปลง session เป็นข้อความเพื่อเก็บ และกลับมาเป็น session
///
/// แยกออกมาเพื่อให้ที่เก็บทุกแบบใช้กฎเดียวกัน
class SessionCodec {
  const SessionCodec();

  String encode(AuthSession session) => jsonEncode({
    'schemaVersion': sessionSchemaVersion,
    'serverId': session.serverId,
    'username': session.username,
    'accessToken': session.accessToken,
    'expiresAt': session.expiresAt.toIso8601String(),
    'roles': session.roles.toList(),
  });

  /// คืน null เมื่ออ่านไม่ได้ — ข้อมูลที่เสียไม่ควรทำให้เปิดแอปไม่ได้ (8.6)
  AuthSession? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;

    // รุ่นที่ไม่รู้จักถือว่าอ่านไม่ได้ ไม่ใช่พยายามเดา
    if (json['schemaVersion'] != sessionSchemaVersion) return null;

    final token = json['accessToken'];
    final serverId = json['serverId'];
    final username = json['username'];
    final expiresAt = DateTime.tryParse('${json['expiresAt']}');

    if (token is! String ||
        token.isEmpty ||
        serverId is! String ||
        serverId.isEmpty ||
        username is! String ||
        expiresAt == null) {
      return null;
    }

    return AuthSession(
      accessToken: token,
      expiresAt: expiresAt.toUtc(),
      username: username,
      serverId: serverId,
      roles: {
        for (final role in (json['roles'] as List?) ?? const [])
          if (role is String && role.isNotEmpty) role,
      },
    );
  }
}

/// ที่เก็บในหน่วยความจำ สำหรับเทสต์
///
/// จำลองความล้มเหลวได้ เพราะที่เก็บจริงเขียนไม่สำเร็จได้ และนั่นคือกรณี
/// ที่ต้องออกแบบไว้ ไม่ใช่กรณีที่หวังว่าจะไม่เกิด
class InMemorySessionStorage implements SessionStorage {
  InMemorySessionStorage({this.codec = const SessionCodec()});

  final SessionCodec codec;

  String? raw;
  bool failOnWrite = false;
  bool failOnRead = false;

  @override
  Future<AuthSession?> read() async {
    if (failOnRead) {
      throw const SessionStorageException('อ่านข้อมูลที่เก็บไว้ไม่ได้');
    }
    return codec.decode(raw);
  }

  @override
  Future<void> write(AuthSession session) async {
    if (failOnWrite) {
      throw const SessionStorageException('บันทึกข้อมูลลงเครื่องไม่ได้');
    }
    raw = codec.encode(session);
  }

  @override
  Future<void> clear() async {
    raw = null;
  }
}
