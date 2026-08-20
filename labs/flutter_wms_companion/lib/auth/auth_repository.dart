import '../core/api_client.dart';
import '../core/api_failure.dart';
import '../core/json_api.dart';
import 'auth_session.dart';
import 'jwt.dart';

/// ผลของการพยายามเข้าสู่ระบบ
///
/// คืนค่าแทนการโยน เพราะ "รหัสผ่านผิด" เป็นเรื่องปกติที่เกิดทุกวัน
/// ไม่ใช่ข้อยกเว้น (7.10)
sealed class LoginOutcome {
  const LoginOutcome();
}

class LoginSucceeded extends LoginOutcome {
  const LoginSucceeded(this.session);
  final AuthSession session;
}

/// ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง
///
/// ไม่แยกว่าอันไหนผิด เพราะการบอกว่า "ไม่มีผู้ใช้นี้" ทำให้เดาชื่อผู้ใช้ได้
class InvalidCredentials extends LoginOutcome {
  const InvalidCredentials();
}

/// บัญชีถูกระงับหรือยังไม่ได้รับอนุญาต
class AccountNotAllowed extends LoginOutcome {
  const AccountNotAllowed(this.message);
  final String message;
}

class LoginFailed extends LoginOutcome {
  const LoginFailed(this.kind, this.message);
  final ApiFailureKind kind;
  final String message;

  bool get canRetry => kind.isRetryable;
}

/// กดเข้าสู่ระบบซ้ำระหว่างที่ครั้งก่อนยังไม่จบ
///
/// เป็นผลลัพธ์หนึ่งของการเรียก ไม่ใช่ความล้มเหลว — จึงอยู่ในชนิดเดียวกัน
/// แทนที่จะโยนหรือคืน null (4.14)
class LoginAlreadyInProgress extends LoginOutcome {
  const LoginAlreadyInProgress();
}

abstract interface class AuthRepository {
  Future<LoginOutcome> login({
    required String username,
    required String password,
    required String serverId,
  });
}

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this.api);

  final JsonApi api;

  @override
  Future<LoginOutcome> login({
    required String username,
    required String password,
    required String serverId,
  }) async {
    final Map<String, dynamic> json;
    try {
      json = await api.postJson('/api/Authenticate/login', {
        'username': username,
        'password': password,
      });
    } on ApiException catch (error) {
      return switch (error.kind) {
        ApiFailureKind.unauthorized => const InvalidCredentials(),
        ApiFailureKind.forbidden => AccountNotAllowed(error.userMessage),
        _ => LoginFailed(error.kind, error.userMessage),
      };
    }

    // อ่านคำตอบอยู่นอก try โดยตั้งใจ — คำตอบที่ผิดสัญญาต้องโยนออกไป
    // ไม่ใช่กลายเป็น LoginFailed เพราะผู้ใช้ทำอะไรกับมันไม่ได้ ทีมต้องแก้ (7.10)
    return LoginSucceeded(
      _readSession(json, serverId: serverId, fallbackUsername: username),
    );
  }

  AuthSession _readSession(
    Map<String, dynamic> json, {
    required String serverId,
    required String fallbackUsername,
  }) {
    final token = json['token'];
    if (token is! String || token.trim().isEmpty) {
      throw const ApiException(
        'คำตอบจากเซิร์ฟเวอร์ไม่มี token',
        kind: ApiFailureKind.contract,
      );
    }

    final payload = tryDecodeJwt(token);

    // เชื่อ expiration ที่ server ส่งมาก่อน แล้วค่อยดูใน token
    // เพราะ server อาจตั้งอายุสั้นกว่าที่เขียนไว้ใน token ได้
    final expiresAt = _readTime(json['expiration']) ?? payload?.expiresAt;
    if (expiresAt == null) {
      throw const ApiException(
        'คำตอบจากเซิร์ฟเวอร์ไม่มีเวลาหมดอายุ',
        kind: ApiFailureKind.contract,
      );
    }

    return AuthSession(
      accessToken: token.trim(),
      expiresAt: expiresAt,
      // อ่านจากคำตอบก่อน ถ้าไม่มีค่อยแกะจาก token และสุดท้ายใช้ชื่อที่กรอกมา
      username:
          _readText(json['username']) ??
          payload?.username ??
          fallbackUsername,
      serverId: serverId,
      roles: _readRoles(json['roles']) ?? payload?.roles ?? const {},
    );
  }

  static String? _readText(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static DateTime? _readTime(Object? value) {
    final raw = _readText(value);
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    return parsed?.toUtc();
  }

  static Set<String>? _readRoles(Object? value) => switch (value) {
    List<Object?> values => {for (final role in values) ?_readText(role)},
    String role when role.trim().isNotEmpty => {role.trim()},
    _ => null,
  };
}
