import 'package:flutter/foundation.dart';

import 'auth_repository.dart';
import 'auth_session.dart';
import 'session_storage.dart';

/// สถานะของการเข้าสู่ระบบ
enum AuthStatus {
  /// ยังไม่รู้ — กำลังอ่านข้อมูลที่เก็บไว้ตอนเปิดแอป
  unknown,

  signedOut,

  /// กำลังส่งชื่อผู้ใช้และรหัสผ่าน
  signingIn,

  signedIn,
}

/// เหตุผลที่หลุดออกจากระบบ — ใช้บอกผู้ใช้ว่าเกิดอะไร (8.7)
enum SignOutReason {
  /// ผู้ใช้กดออกเอง
  userRequested,

  /// token หมดอายุ หรือ server ปฏิเสธ
  sessionExpired,

  /// สลับไปเซิร์ฟเวอร์อื่น
  serverChanged,
}

/// เจ้าของสถานะการเข้าสู่ระบบของทั้งแอป
///
/// ตัวเดียวในแอป เพราะ token ต้องมีชุดเดียว — ถ้ามีสองที่ จะเกิดกรณีที่
/// ส่วนหนึ่งของแอปยังใช้ token เก่าอยู่หลังออกจากระบบแล้ว (7.5)
class SessionStore extends ChangeNotifier {
  SessionStore({
    required this.repository,
    required this.storage,
    required this.onTokenChanged,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AuthRepository repository;
  final SessionStorage storage;

  /// เรียกทุกครั้งที่ token เปลี่ยน เพื่อให้ ApiClient ใช้ค่าล่าสุด
  ///
  /// ใช้ callback แทนการถือ ApiClient ไว้ตรง ๆ เพื่อให้ทดสอบได้
  /// โดยไม่ต้องสร้างตัวส่ง HTTP
  final void Function(String? token) onTokenChanged;

  final DateTime Function() _clock;

  AuthStatus _status = AuthStatus.unknown;
  AuthSession? _session;
  String? _errorMessage;
  SignOutReason? _lastSignOutReason;

  AuthStatus get status => _status;
  AuthSession? get session => _session;
  String? get errorMessage => _errorMessage;
  SignOutReason? get lastSignOutReason => _lastSignOutReason;

  bool get isSignedIn => _status == AuthStatus.signedIn;

  /// อ่าน session ที่เก็บไว้ตอนเปิดแอป
  ///
  /// [currentServerId] คือเซิร์ฟเวอร์ที่ตั้งค่าไว้ตอนนี้ — ถ้าไม่ตรงกับที่
  /// เก็บไว้ แปลว่ามีคนสลับเซิร์ฟเวอร์ และ token เก่าใช้ไม่ได้ (8.11)
  Future<void> restore({required String currentServerId}) async {
    _status = AuthStatus.unknown;
    notifyListeners();

    AuthSession? stored;
    try {
      stored = await storage.read();
    } on SessionStorageException {
      // อ่านไม่ได้ก็แค่ให้ล็อกอินใหม่ ไม่ควรทำให้เปิดแอปไม่ได้
      stored = null;
    }

    if (stored == null) {
      await _clearTo(AuthStatus.signedOut);
      return;
    }
    if (stored.serverId != currentServerId) {
      await _clearTo(AuthStatus.signedOut, reason: SignOutReason.serverChanged);
      return;
    }
    if (stored.isExpiredAt(_clock())) {
      await _clearTo(AuthStatus.signedOut, reason: SignOutReason.sessionExpired);
      return;
    }

    _applySession(stored);
  }

  Future<LoginOutcome> signIn({
    required String username,
    required String password,
    required String serverId,
  }) async {
    // กันการกดซ้ำระหว่างที่ยังส่งอยู่ (4.14)
    if (_status == AuthStatus.signingIn) return const LoginAlreadyInProgress();

    _status = AuthStatus.signingIn;
    _errorMessage = null;
    notifyListeners();

    final outcome = await repository.login(
      username: username,
      password: password,
      serverId: serverId,
    );

    switch (outcome) {
      case LoginSucceeded(:final session):
        // เก็บลงเครื่องก่อน แล้วค่อยประกาศว่าเข้าสู่ระบบแล้ว
        // ถ้าเก็บไม่ได้ ยังใช้งานได้ในรอบนี้ แต่เปิดแอปใหม่ต้องล็อกอินอีก
        try {
          await storage.write(session);
        } on SessionStorageException {
          _errorMessage = 'เข้าสู่ระบบได้ แต่จำไว้ให้ไม่ได้ '
              'ครั้งหน้าต้องเข้าสู่ระบบใหม่';
        }
        _applySession(session);
      case InvalidCredentials():
        _status = AuthStatus.signedOut;
        _errorMessage = 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง';
        notifyListeners();
      case AccountNotAllowed(:final message):
        _status = AuthStatus.signedOut;
        _errorMessage = message;
        notifyListeners();
      case LoginFailed(:final message):
        _status = AuthStatus.signedOut;
        _errorMessage = message;
        notifyListeners();
      case LoginAlreadyInProgress():
        // เกิดไม่ได้ — ถูกกันไว้ที่ต้นเมธอดแล้ว แต่ต้องเขียนให้ครบ
        // เพื่อให้ compiler เตือนถ้ามีการเพิ่มผลลัพธ์ใหม่ (6.9)
        break;
    }

    return outcome;
  }

  /// ออกจากระบบ — ล้างทุกอย่างที่ผูกกับผู้ใช้คนนี้
  Future<void> signOut({
    SignOutReason reason = SignOutReason.userRequested,
  }) => _clearTo(AuthStatus.signedOut, reason: reason);

  /// เรียกเมื่อ server ตอบ 401 — token ใช้ไม่ได้แล้ว
  ///
  /// ทำครั้งเดียวแม้จะได้ 401 มาหลายครั้งพร้อมกัน เพราะคำขอหลายตัว
  /// ที่วิ่งขนานกันจะได้ 401 พร้อมกันหมด (5.4)
  Future<void> handleUnauthorized() async {
    if (_status != AuthStatus.signedIn) return;
    await _clearTo(AuthStatus.signedOut, reason: SignOutReason.sessionExpired);
  }

  void _applySession(AuthSession session) {
    _session = session;
    _status = AuthStatus.signedIn;
    _lastSignOutReason = null;
    onTokenChanged(session.accessToken);
    notifyListeners();
  }

  Future<void> _clearTo(AuthStatus status, {SignOutReason? reason}) async {
    // ล้าง token ก่อนเสมอ ไม่ให้มีคำขอไหนยิงด้วย token เก่าได้อีก
    onTokenChanged(null);
    _session = null;
    _status = status;
    _lastSignOutReason = reason;
    try {
      await storage.clear();
    } on SessionStorageException {
      // ล้างไม่ได้ก็ยังต้องออกจากระบบในรอบนี้ให้ได้
    }
    notifyListeners();
  }
}
