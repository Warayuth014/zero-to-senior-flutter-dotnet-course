import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/auth/auth_repository.dart';
import 'package:flutter_wms_companion/auth/auth_session.dart';
import 'package:flutter_wms_companion/auth/jwt.dart';
import 'package:flutter_wms_companion/auth/session_storage.dart';
import 'package:flutter_wms_companion/auth/session_store.dart';
import 'package:flutter_wms_companion/core/api_client.dart';
import 'package:flutter_wms_companion/core/api_failure.dart';
import 'package:flutter_wms_companion/core/json_api.dart';

/// สร้าง token ปลอมที่มีโครงเหมือนของจริง
///
/// ไม่ได้เซ็นจริง เพราะฝั่งแอปตรวจลายเซ็นไม่ได้อยู่แล้ว — สิ่งที่ต้องทดสอบ
/// คือการอ่านเนื้อหา ไม่ใช่การตรวจสอบ
String fakeJwt(Map<String, Object?> claims) {
  String encode(Map<String, Object?> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');
  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${encode(claims)}'
      '.ลายเซ็นปลอม';
}

class FakeJsonApi implements JsonApi {
  Map<String, dynamic> loginResponse = const {};
  ApiException? failWith;
  Map<String, dynamic>? sentBody;

  @override
  Future<Map<String, dynamic>> getJson(String path) async => const {};

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    sentBody = body;
    if (failWith case final error?) throw error;
    return loginResponse;
  }
}

void main() {
  final expiry = DateTime.utc(2026, 8, 15, 10);
  final now = DateTime.utc(2026, 8, 15, 9);

  Map<String, dynamic> loginJson({
    String token = 'token-abc',
    String? expiration,
    Object? roles,
    String? username,
  }) => {
    'token': token,
    'expiration': expiration ?? expiry.toIso8601String(),
    // `?` ข้างหน้าค่า แปลว่า "ใส่คีย์นี้เฉพาะเมื่อค่าไม่เป็น null"
    'roles': ?roles,
    'username': ?username,
  };

  group('อ่านเนื้อหาใน token', () {
    test('อ่าน exp ที่เป็นวินาทีนับจากปี 1970 ได้', () {
      final payload = tryDecodeJwt(
        fakeJwt({'exp': expiry.millisecondsSinceEpoch ~/ 1000}),
      );

      expect(payload!.expiresAt, expiry);
    });

    test('รับ role ทั้งแบบข้อความเดี่ยวและแบบรายการ', () {
      expect(tryDecodeJwt(fakeJwt({'role': 'PICKER'}))!.roles, {'PICKER'});
      expect(
        tryDecodeJwt(fakeJwt({'role': ['PICKER', 'SUPERVISOR']}))!.roles,
        {'PICKER', 'SUPERVISOR'},
      );
    });

    test('อ่าน role จากชื่อ claim แบบยาวของ .NET ได้', () {
      final payload = tryDecodeJwt(fakeJwt({dotNetRoleClaim: 'ADMIN'}));

      expect(payload!.roles, {'ADMIN'});
    });

    test('token ที่รูปแบบผิดต้องคืน null ไม่ใช่โยน', () {
      expect(tryDecodeJwt('ไม่ใช่ token'), isNull);
      expect(tryDecodeJwt('a.b'), isNull);
      expect(tryDecodeJwt('a.ข้อความที่ไม่ใช่ base64.c'), isNull);
    });
  });

  group('อายุของ session', () {
    AuthSession sessionExpiringAt(DateTime at) => AuthSession(
      accessToken: 'token',
      expiresAt: at,
      username: 'somchai',
      serverId: 'wh-01',
    );

    test('ยังไม่หมดอายุเมื่อเหลือเวลาอีกมาก', () {
      expect(sessionExpiringAt(expiry).isExpiredAt(now), isFalse);
    });

    test('ถือว่าหมดอายุก่อนเวลาจริง เพราะเผื่อเวลาเดินทาง', () {
      // เหลืออีก 30 วินาที แต่เผื่อไว้ 60 จึงถือว่าหมดแล้ว
      final almost = expiry.subtract(const Duration(seconds: 30));

      expect(sessionExpiringAt(expiry).isExpiredAt(almost), isTrue);
    });

    test('ปรับเวลาที่เผื่อได้', () {
      final almost = expiry.subtract(const Duration(seconds: 30));

      expect(
        sessionExpiringAt(expiry).isExpiredAt(almost, skew: Duration.zero),
        isFalse,
      );
    });

    test('ไม่พิมพ์ token ออกมาใน toString', () {
      final text = sessionExpiringAt(expiry).toString();

      expect(text, contains('somchai'));
      expect(text, isNot(contains('token')));
    });
  });

  group('เข้าสู่ระบบ', () {
    late FakeJsonApi api;
    late RemoteAuthRepository repository;

    setUp(() {
      api = FakeJsonApi();
      repository = RemoteAuthRepository(api);
    });

    test('สำเร็จแล้วได้ session ที่ผูกกับเซิร์ฟเวอร์', () async {
      api.loginResponse = loginJson(roles: ['PICKER'], username: 'somchai');

      final outcome = await repository.login(
        username: 'somchai',
        password: 'รหัสผ่าน',
        serverId: 'wh-01',
      );

      expect(outcome, isA<LoginSucceeded>());
      final session = (outcome as LoginSucceeded).session;
      expect(session.accessToken, 'token-abc');
      expect(session.serverId, 'wh-01');
      expect(session.roles, {'PICKER'});
    });

    test('อ่าน role จาก token เมื่อ server ไม่ได้ส่งมาแยก', () async {
      api.loginResponse = loginJson(
        token: fakeJwt({'name': 'somchai', 'role': 'SUPERVISOR'}),
      );

      final outcome = await repository.login(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      expect((outcome as LoginSucceeded).session.roles, {'SUPERVISOR'});
    });

    test('401 คือรหัสผ่านผิด ไม่ใช่ความล้มเหลวของระบบ', () async {
      api.failWith = const ApiException(
        'unauthorized',
        statusCode: 401,
        kind: ApiFailureKind.unauthorized,
      );

      final outcome = await repository.login(
        username: 'somchai',
        password: 'ผิด',
        serverId: 'wh-01',
      );

      expect(outcome, isA<InvalidCredentials>());
    });

    test('403 คือบัญชีใช้ไม่ได้ ต่างจากรหัสผ่านผิด', () async {
      api.failWith = const ApiException(
        'บัญชีถูกระงับ',
        statusCode: 403,
        kind: ApiFailureKind.forbidden,
      );

      final outcome = await repository.login(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      expect(outcome, isA<AccountNotAllowed>());
    });

    test('เน็ตหลุดยังไม่รู้ว่ารหัสผ่านถูกหรือผิด และลองใหม่ได้', () async {
      api.failWith = const ApiException(
        'เชื่อมต่อไม่ได้',
        kind: ApiFailureKind.network,
      );

      final outcome = await repository.login(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      expect(outcome, isA<LoginFailed>());
      expect((outcome as LoginFailed).canRetry, isTrue);
    });

    test('คำตอบที่ไม่มี token ถือว่าผิดสัญญา', () async {
      api.loginResponse = const {'expiration': '2026-08-15T10:00:00Z'};

      await expectLater(
        repository.login(username: 'a', password: 'b', serverId: 'wh-01'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.contract,
          ),
        ),
      );
    });

    test('ไม่ส่งรหัสผ่านกลับมาใน body ที่บันทึกไว้', () async {
      api.loginResponse = loginJson();

      await repository.login(
        username: 'somchai',
        password: 'ลับมาก',
        serverId: 'wh-01',
      );

      // ยืนยันว่ารหัสผ่านถูกส่งไปจริง — แต่จะไม่ถูกบันทึกที่ไหน (8.10)
      expect(api.sentBody, {'username': 'somchai', 'password': 'ลับมาก'});
    });
  });

  group('เก็บและอ่าน session', () {
    const codec = SessionCodec();

    final session = AuthSession(
      accessToken: 'token-abc',
      expiresAt: expiry,
      username: 'somchai',
      serverId: 'wh-01',
      roles: const {'PICKER'},
    );

    test('เก็บแล้วอ่านกลับได้เหมือนเดิม', () {
      expect(codec.decode(codec.encode(session)), session);
    });

    test('ข้อมูลที่เสียต้องคืน null ไม่ใช่ทำให้เปิดแอปไม่ได้', () {
      expect(codec.decode('ไม่ใช่ JSON'), isNull);
      expect(codec.decode('{}'), isNull);
      expect(codec.decode(null), isNull);
    });

    test('ข้อมูลของรุ่นเก่าต้องไม่ถูกเดา', () {
      final old = jsonEncode({
        'schemaVersion': 0,
        'serverId': 'wh-01',
        'username': 'somchai',
        'accessToken': 'token-abc',
        'expiresAt': expiry.toIso8601String(),
      });

      expect(codec.decode(old), isNull);
    });
  });

  group('เจ้าของสถานะการเข้าสู่ระบบ', () {
    late FakeJsonApi api;
    late InMemorySessionStorage storage;
    late List<String?> tokens;
    late SessionStore store;

    setUp(() {
      api = FakeJsonApi()..loginResponse = loginJson(roles: ['PICKER']);
      storage = InMemorySessionStorage();
      tokens = <String?>[];
      store = SessionStore(
        repository: RemoteAuthRepository(api),
        storage: storage,
        onTokenChanged: tokens.add,
        clock: () => now,
      );
      addTearDown(store.dispose);
    });

    test('เข้าสู่ระบบแล้ว token ถูกส่งต่อและเก็บลงเครื่อง', () async {
      await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      expect(store.status, AuthStatus.signedIn);
      expect(tokens, ['token-abc']);
      expect(storage.raw, isNotNull);
    });

    test('กดซ้ำระหว่างกำลังเข้าสู่ระบบ ต้องไม่ยิงสองครั้ง', () async {
      final first = store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );
      final second = await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );
      await first;

      expect(second, isA<LoginAlreadyInProgress>());
    });

    test('รหัสผ่านผิดต้องไม่เก็บอะไรลงเครื่อง', () async {
      api.failWith = const ApiException(
        'unauthorized',
        statusCode: 401,
        kind: ApiFailureKind.unauthorized,
      );

      await store.signIn(
        username: 'somchai',
        password: 'ผิด',
        serverId: 'wh-01',
      );

      expect(store.status, AuthStatus.signedOut);
      expect(storage.raw, isNull);
      expect(tokens, isEmpty);
    });

    test('เก็บลงเครื่องไม่ได้ ยังใช้งานรอบนี้ได้ แต่ต้องบอกผู้ใช้', () async {
      storage.failOnWrite = true;

      await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      expect(store.status, AuthStatus.signedIn);
      expect(store.errorMessage, contains('ครั้งหน้าต้องเข้าสู่ระบบใหม่'));
    });

    test('ออกจากระบบต้องล้าง token ก่อนล้างที่เก็บ', () async {
      await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      await store.signOut();

      expect(store.status, AuthStatus.signedOut);
      expect(store.session, isNull);
      expect(tokens, ['token-abc', null]);
      expect(storage.raw, isNull);
    });

    test('ได้ 401 ระหว่างใช้งาน ต้องออกจากระบบพร้อมบอกเหตุผล', () async {
      await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      await store.handleUnauthorized();

      expect(store.status, AuthStatus.signedOut);
      expect(store.lastSignOutReason, SignOutReason.sessionExpired);
    });

    test('ได้ 401 หลายครั้งพร้อมกัน ต้องล้าง token ครั้งเดียว', () async {
      await store.signIn(
        username: 'somchai',
        password: 'x',
        serverId: 'wh-01',
      );

      await Future.wait([
        store.handleUnauthorized(),
        store.handleUnauthorized(),
        store.handleUnauthorized(),
      ]);

      // ['token-abc', null] — ไม่ใช่ null ซ้ำสามครั้ง
      expect(tokens, ['token-abc', null]);
    });
  });

  group('เปิดแอปแล้วอ่าน session เดิม', () {
    late InMemorySessionStorage storage;
    late List<String?> tokens;

    SessionStore storeWithClock(DateTime clockNow) {
      final store = SessionStore(
        repository: RemoteAuthRepository(FakeJsonApi()),
        storage: storage,
        onTokenChanged: tokens.add,
        clock: () => clockNow,
      );
      addTearDown(store.dispose);
      return store;
    }

    setUp(() {
      storage = InMemorySessionStorage();
      tokens = <String?>[];
    });

    Future<void> saveSession({
      String serverId = 'wh-01',
      DateTime? expiresAt,
    }) => storage.write(
      AuthSession(
        accessToken: 'token-abc',
        expiresAt: expiresAt ?? expiry,
        username: 'somchai',
        serverId: serverId,
      ),
    );

    test('ไม่มีข้อมูลเก็บไว้ ต้องไปหน้าเข้าสู่ระบบ', () async {
      final store = storeWithClock(now);

      await store.restore(currentServerId: 'wh-01');

      expect(store.status, AuthStatus.signedOut);
      // ล้าง token เสมอแม้ไม่เคยมี เพื่อรับประกันว่า ApiClient ไม่มีของค้าง
      expect(tokens, [null]);
    });

    test('มีข้อมูลที่ยังไม่หมดอายุ ต้องเข้าใช้งานได้เลย', () async {
      await saveSession();
      final store = storeWithClock(now);

      await store.restore(currentServerId: 'wh-01');

      expect(store.status, AuthStatus.signedIn);
      expect(tokens, ['token-abc']);
    });

    test('หมดอายุแล้วต้องล้างทิ้ง ไม่ใช่ปล่อยให้ใช้ต่อ', () async {
      await saveSession();
      final store = storeWithClock(expiry.add(const Duration(minutes: 1)));

      await store.restore(currentServerId: 'wh-01');

      expect(store.status, AuthStatus.signedOut);
      expect(store.lastSignOutReason, SignOutReason.sessionExpired);
      expect(storage.raw, isNull);
    });

    test('สลับเซิร์ฟเวอร์แล้ว token เก่าใช้ไม่ได้', () async {
      await saveSession(serverId: 'wh-01');
      final store = storeWithClock(now);

      await store.restore(currentServerId: 'wh-02');

      expect(store.status, AuthStatus.signedOut);
      expect(store.lastSignOutReason, SignOutReason.serverChanged);
      // token ของสาขาเก่าต้องไม่ถูกส่งต่อไปให้ ApiClient เลยแม้แต่ครั้งเดียว
      expect(tokens, [null]);
    });

    test('อ่านที่เก็บไม่ได้ ต้องไม่ทำให้เปิดแอปไม่ได้', () async {
      storage.failOnRead = true;
      final store = storeWithClock(now);

      await store.restore(currentServerId: 'wh-01');

      expect(store.status, AuthStatus.signedOut);
    });
  });
}
