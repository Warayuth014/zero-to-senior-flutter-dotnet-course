/// ข้อมูลของผู้ใช้ที่เข้าสู่ระบบอยู่
///
/// ผูกกับ [serverId] ด้วย เพราะ PDA เครื่องเดียวอาจสลับไปคุยกับเซิร์ฟเวอร์
/// ของอีกสาขาได้ และ token ของสาขาหนึ่งใช้กับอีกสาขาไม่ได้ (8.11)
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.expiresAt,
    required this.username,
    required this.serverId,
    this.roles = const {},
  });

  final String accessToken;

  /// เก็บเป็น UTC เสมอ ตามที่ตกลงไว้ใน 6.6
  final DateTime expiresAt;

  final String username;

  /// ระบุว่า token นี้เป็นของเซิร์ฟเวอร์ไหน
  final String serverId;

  final Set<String> roles;

  /// หมดอายุแล้วหรือยัง โดยเผื่อเวลาไว้ล่วงหน้า
  ///
  /// เผื่อ [skew] เพราะนาฬิกาของ PDA กับของ server ไม่ตรงกันเป๊ะ และเพราะ
  /// คำขอที่ยิงตอนเหลืออีก 2 วินาที จะหมดอายุระหว่างเดินทาง
  bool isExpiredAt(
    DateTime now, {
    Duration skew = const Duration(seconds: 60),
  }) => !now.toUtc().isBefore(expiresAt.subtract(skew));

  /// ใช้ปรับหน้าจอเท่านั้น — ห้ามใช้แทนการตรวจสิทธิ์ที่ server (8.9)
  bool hasRole(String role) => roles.contains(role);

  AuthSession copyWith({String? accessToken, DateTime? expiresAt}) =>
      AuthSession(
        accessToken: accessToken ?? this.accessToken,
        expiresAt: expiresAt ?? this.expiresAt,
        username: username,
        serverId: serverId,
        roles: roles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          other.accessToken == accessToken &&
          other.expiresAt == expiresAt &&
          other.username == username &&
          other.serverId == serverId &&
          other.roles.length == roles.length &&
          other.roles.containsAll(roles);

  @override
  int get hashCode => Object.hash(
    accessToken,
    expiresAt,
    username,
    serverId,
    Object.hashAllUnordered(roles),
  );

  /// ไม่พิมพ์ token ออกมา เพราะ toString ไปโผล่ใน log ได้ง่าย (7.17)
  @override
  String toString() =>
      'AuthSession($username @ $serverId, หมดอายุ $expiresAt)';
}
