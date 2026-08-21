import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/settings_lab/health_probe.dart';
import 'package:flutter_wms_companion/settings_lab/profile_draft.dart';
import 'package:flutter_wms_companion/settings_lab/profile_snapshot.dart';
import 'package:flutter_wms_companion/settings_lab/profile_store.dart';
import 'package:flutter_wms_companion/settings_lab/profile_validation.dart';
import 'package:flutter_wms_companion/settings_lab/server_profile.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ServerProfile profile(
  String id, {
  String name = 'Office',
  String host = '192.168.1.194',
  int port = 6191,
  String basePath = '',
  ServerProtocol protocol = ServerProtocol.http,
}) => ServerProfile(
  id: id,
  name: name,
  environment: ServerEnvironment.development,
  protocol: protocol,
  host: host,
  port: port,
  basePath: basePath,
);

ProfileDraft draft({
  String? id,
  String name = 'Office',
  String host = '192.168.1.194',
  String port = '6191',
  String basePath = '',
}) => ProfileDraft(
  id: id,
  name: name,
  host: host,
  port: port,
  basePath: basePath,
);

void main() {
  group('normalizeBasePath', () {
    test('รูปแบบที่ผู้ใช้พิมพ์ได้ทั้งหมด ต้องให้ผลเดียวกัน', () {
      for (final raw in ['wms', '/wms', 'wms/', '/wms/', '//wms//', ' /wms ']) {
        expect(normalizeBasePath(raw), '/wms', reason: 'ผิดที่ "$raw"');
      }
    });

    test('ว่างหรือมีแต่ทับ ต้องได้ข้อความว่าง ไม่ใช่ทับเดี่ยว', () {
      // ถ้าคืน '/' จะได้ URL แบบ http://host:6191//api/WMS ซึ่งบางเซิร์ฟเวอร์
      // ตอบ 404 และบางตัวไม่ — ความไม่แน่นอนแบบนี้ต้องตัดทิ้งตั้งแต่ต้นทาง
      expect(normalizeBasePath(''), '');
      expect(normalizeBasePath('   '), '');
      expect(normalizeBasePath('/'), '');
      expect(normalizeBasePath('///'), '');
    });

    test('เส้นทางหลายชั้นเก็บครบ', () {
      expect(normalizeBasePath('/wms/pda/'), '/wms/pda');
    });
  });

  group('baseUrl', () {
    test('ประกอบจากทุกช่องตามลำดับที่ถูก', () {
      expect(profile('p1').baseUrl, 'http://192.168.1.194:6191');
      expect(
        profile('p1', protocol: ServerProtocol.https, basePath: 'wms').baseUrl,
        'https://192.168.1.194:6191/wms',
      );
    });
  });

  group('การตรวจฟอร์ม', () {
    test('ฟอร์มที่ถูกต้องผ่านทุกช่อง', () {
      expect(validateDraft(draft()).isValid, isTrue);
    });

    test('พิมพ์ที่อยู่เต็มลงช่อง host ต้องบอกว่าให้ไปเลือกที่ Protocol', () {
      final result = validateDraft(draft(host: 'http://192.168.1.194'));
      expect(result.host, contains('Protocol'));
      // ช่องอื่นต้องไม่พลอยผิดไปด้วย ผู้ใช้จะได้รู้ว่าต้องแก้ตรงไหน
      expect(result.port, isNull);
      expect(result.name, isNull);
    });

    test('ใส่พอร์ตติดมากับ host ต้องบอกว่าให้ไปช่อง Port', () {
      expect(validateDraft(draft(host: '192.168.1.194:6191')).host,
          contains('Port'));
    });

    test('พอร์ตที่ยังพิมพ์ไม่เสร็จ ต้องไม่ทำให้พังทั้งฟอร์ม', () {
      // ระหว่างพิมพ์ ค่ายังเป็น "" หรือ "61" ซึ่งแปลงเป็น int ไม่ได้
      // นี่คือเหตุผลที่ ProfileDraft เก็บ port เป็น String
      expect(validateDraft(draft(port: '')).port, isNotNull);
      expect(validateDraft(draft(port: '61')).port, isNull);
    });

    test('พอร์ตนอกช่วงถูกปฏิเสธ', () {
      expect(validateDraft(draft(port: '0')).port, isNotNull);
      expect(validateDraft(draft(port: '65536')).port, isNotNull);
      expect(validateDraft(draft(port: '65535')).port, isNull);
    });

    test('ใส่ /api ลง Base Path ต้องถูกดักพร้อมบอกว่าจะเกิดอะไร', () {
      final message = validateDraft(draft(basePath: '/api')).basePath;
      expect(message, isNotNull);
      // ข้อความต้องบอกผลที่จะเกิด ไม่ใช่แค่บอกว่าผิด
      expect(message, contains('/api/.../api/'));
    });

    test('ดัก /api ได้ทุกรูปแบบที่พิมพ์', () {
      for (final raw in ['api', '/api', 'api/', '/API/wms']) {
        expect(validateDraft(draft(basePath: raw)).basePath, isNotNull,
            reason: 'ไม่ได้ดัก "$raw"');
      }
    });

    test('Base Path ที่ไม่ใช่ /api ผ่าน', () {
      expect(validateDraft(draft(basePath: '/wms')).basePath, isNull);
    });
  });

  group('ร่างที่ยังไม่บันทึก', () {
    test('ร่างเปล่าที่ยังไม่พิมพ์อะไร ปิดได้โดยไม่ต้องเตือน', () {
      expect(ProfileDraft().isDirtyFrom(null), isFalse);
    });

    test('พิมพ์ไปแล้วแม้ช่องเดียว ต้องเตือนก่อนปิด', () {
      expect(ProfileDraft(host: '10.0.0.1').isDirtyFrom(null), isTrue);
    });

    test('เปิดของเดิมมาแล้วยังไม่แก้ ต้องไม่เตือน', () {
      final saved = profile('p1');
      expect(ProfileDraft.from(saved).isDirtyFrom(saved), isFalse);
    });

    test('เปลี่ยนแค่ชื่อก็นับว่าแก้ ทั้งที่ที่อยู่เท่าเดิม', () {
      final saved = profile('p1');
      final edited = ProfileDraft.from(saved)..name = 'Office ชั้น 2';
      expect(edited.isDirtyFrom(saved), isTrue);
    });

    test('เว้นวรรคหัวท้ายไม่นับว่าแก้', () {
      final saved = profile('p1');
      final edited = ProfileDraft.from(saved)..host = ' 192.168.1.194 ';
      expect(edited.isDirtyFrom(saved), isFalse);
    });

    test('แปลงร่างที่ยังไม่ผ่านการตรวจ ต้องดังไม่ใช่เงียบ', () {
      expect(
        () => draft(port: 'abc').toProfile(id: 'p1'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('เก็บและอ่านกลับ', () {
    test('เขียนแล้วอ่านกลับได้เหมือนเดิม พร้อมตัวที่ใช้งานอยู่', () {
      final raw = encodeProfiles([profile('p1'), profile('p2')], 'p2');
      final snapshot = decodeProfiles(raw);

      expect(snapshot.profiles.map((p) => p.id), ['p1', 'p2']);
      expect(snapshot.activeId, 'p2');
    });

    test('แถวเสียหนึ่งแถว ต้องไม่ทำให้เสีย profile อื่นทั้งหมด', () {
      final raw = jsonEncode({
        'version': 1,
        'profiles': [
          profile('p1').toJson(isActive: true),
          {'id': 'broken'}, // ไม่มี host และ port
          profile('p3').toJson(),
        ],
      });

      final snapshot = decodeProfiles(raw);
      expect(snapshot.profiles.map((p) => p.id), ['p1', 'p3']);
      expect(snapshot.activeId, 'p1');
    });

    test('ไม่มีแถวไหนถูกทำเครื่องหมายว่าใช้อยู่ ให้ใช้แถวแรก', () {
      final raw = jsonEncode({
        'version': 1,
        'profiles': [profile('p1').toJson(), profile('p2').toJson()],
      });

      // กฎ "มีตัวที่ใช้งานอยู่หนึ่งตัวเสมอ" ต้องเป็นจริงแม้ไฟล์ถูกแก้ด้วยมือ
      expect(decodeProfiles(raw).activeId, 'p1');
    });

    test('ข้อมูลเสียทั้งไฟล์ ต้องได้ค่าว่าง ไม่ใช่โยน', () {
      for (final raw in [null, '', 'ไม่ใช่ JSON', '[]', '{}']) {
        final snapshot = decodeProfiles(raw);
        expect(snapshot.profiles, isEmpty, reason: 'ผิดที่ "$raw"');
        expect(snapshot.activeId, isNull);
      }
    });

    test('เก็บเลขรุ่นของโครงข้อมูลไว้ด้วย', () {
      final decoded = jsonDecode(encodeProfiles([profile('p1')], 'p1'));
      expect((decoded as Map)['version'], profileSchemaVersion);
    });
  });

  group('ตรวจว่าเซิร์ฟเวอร์ตอบไหม', () {
    MockClient respond(String body, int status) => MockClient(
      (_) async => http.Response(
        body,
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );

    test('คำตอบที่ถูกต้องถือว่าสำเร็จ', () async {
      final result = await probeServer(
        baseUrl: 'http://10.0.0.1:6191',
        client: respond(jsonEncode({'service': 'WMS', 'ok': true}), 200),
      );
      expect(result.ok, isTrue);
      expect(result.statusCode, 200);
    });

    test('ยิงไปที่เส้นทาง health ของ WMS', () async {
      Uri? called;
      await probeServer(
        baseUrl: 'http://10.0.0.1:6191/wms',
        client: MockClient((request) async {
          called = request.url;
          return http.Response('{}', 200);
        }),
      );
      expect(called.toString(), 'http://10.0.0.1:6191/wms/api/WMS/mobile_health');
    });

    test('200 พร้อม HTML ของหน้าเว็บ ต้องไม่ถือว่าสำเร็จ', () async {
      // กับดัก Blazor: MapFallbackToPage ตอบ 200 ให้ทุกเส้นทางที่ไม่รู้จัก
      // ถ้าเชื่อแค่รหัสตอบกลับ Base Path ที่ผิดจะดูเหมือนใช้ได้
      final result = await probeServer(
        baseUrl: 'http://10.0.0.1:6191',
        client: respond('<!DOCTYPE html><html><body>WMS</body></html>', 200),
      );
      expect(result.ok, isFalse);
      expect(result.statusCode, 200);
      expect(result.message, contains('Base Path'));
    });

    test('JSON ที่ไม่ใช่ของเรา ก็ยังไม่ถือว่าสำเร็จ', () async {
      final result = await probeServer(
        baseUrl: 'http://10.0.0.1:6191',
        client: respond(jsonEncode({'service': 'other', 'ok': true}), 200),
      );
      expect(result.ok, isFalse);
    });

    test('ที่อยู่ที่แปลงเป็น URL ไม่ได้ ต้องบอกก่อนยิง', () async {
      var called = false;
      final result = await probeServer(
        baseUrl: 'ไม่ใช่ url',
        client: MockClient((_) async {
          called = true;
          return http.Response('{}', 200);
        }),
      );
      expect(result.ok, isFalse);
      expect(called, isFalse, reason: 'ไม่ควรยิงคำขอเลย');
    });

    test('ต่อไม่ติดต้องบอกให้ตรวจสัญญาณ', () async {
      final result = await probeServer(
        baseUrl: 'http://10.0.0.1:6191',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(result.ok, isFalse);
      expect(result.message, contains('เชื่อมต่อไม่สำเร็จ'));
    });
  });

  group('ProfileStore', () {
    late InMemorySettingsStorage storage;
    var idCounter = 0;

    ProfileStore newStore() {
      idCounter = 0;
      return ProfileStore(storage, createId: () => 'p${++idCounter}');
    }

    setUp(() => storage = InMemorySettingsStorage());

    test('เปิดครั้งแรกต้องมี profile เริ่มต้นให้ใช้ทันที', () async {
      final store = newStore();
      await store.load();

      expect(store.profiles, hasLength(1));
      expect(store.active?.host, defaultServerHost);
      expect(store.activeBaseUrl, 'http://$defaultServerHost:$defaultServerPort');
      expect(store.isLoaded, isTrue);
    });

    test('profile เริ่มต้นถูกบันทึกลงเครื่องด้วย ไม่ใช่สร้างใหม่ทุกครั้ง',
        () async {
      await newStore().load();

      final second = ProfileStore(storage, createId: () => 'ไม่ควรถูกเรียก');
      await second.load();
      expect(second.profiles.single.id, 'p1');
    });

    test('บันทึกตัวใหม่แล้วต้องไม่สลับไปใช้ทันที', () async {
      final store = newStore();
      await store.load();
      final before = store.active!.id;

      await store.saveAsNew(profile('ไม่สน', name: 'เครื่องทดสอบ'));

      expect(store.profiles, hasLength(2));
      expect(store.active!.id, before, reason: 'การบันทึกไม่ใช่การสลับ');
    });

    test('สลับแล้วทุกคำขอหลังจากนี้ชี้ที่ใหม่', () async {
      final store = newStore();
      await store.load();
      final saved = await store.saveAsNew(profile('x', host: '10.0.0.9'));

      await store.activate(saved.id);

      expect(store.activeBaseUrl, 'http://10.0.0.9:6191');
      expect(store.isActive(saved), isTrue);
    });

    test('สลับแล้วต้องลืมผลตรวจของเครื่องเก่า', () async {
      final store = newStore();
      await store.load();
      await store.refreshStatus(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'service': 'WMS', 'ok': true}), 200),
        ),
      );
      expect(store.status, ServerStatus.connected);

      final saved = await store.saveAsNew(profile('x', host: '10.0.0.9'));
      await store.activate(saved.id);

      // จุดสีเขียวที่ค้างอยู่จะบอกว่าเครื่องใหม่ใช้ได้ ทั้งที่ยังไม่เคยตรวจ
      expect(store.status, ServerStatus.unknown);
      expect(store.lastResult, isNull);
    });

    test('สลับไป id ที่ไม่มีอยู่ ต้องไม่ทำให้ไม่มีตัวที่ใช้งานอยู่', () async {
      final store = newStore();
      await store.load();

      await store.activate('ไม่มีจริง');

      expect(store.active, isNotNull);
    });

    test('ลบตัวสุดท้ายไม่ได้', () async {
      final store = newStore();
      await store.load();

      expect(await store.remove(store.active!.id), isFalse);
      expect(store.profiles, hasLength(1));
    });

    test('ลบตัวที่ใช้งานอยู่ ต้องมีตัวใหม่มาแทนเสมอ', () async {
      final store = newStore();
      await store.load();
      final second = await store.saveAsNew(profile('x', host: '10.0.0.9'));
      await store.activate(second.id);

      expect(await store.remove(second.id), isTrue);
      expect(store.active, isNotNull);
      expect(store.activeBaseUrl, isNotNull);
    });

    test('แก้ตัวที่ใช้งานอยู่แล้ว baseUrl เปลี่ยนตามทันที', () async {
      final store = newStore();
      await store.load();
      final current = store.active!;

      await store.saveEdits(current.copyWith(host: '10.0.0.50', port: 8080));

      expect(store.activeBaseUrl, 'http://10.0.0.50:8080');
    });

    test('เขียนลงเครื่องไม่ได้ ต้องยังใช้งานรอบนี้ได้', () async {
      final store = newStore();
      await store.load();
      storage.failOnWrite = true;

      final saved = await store.saveAsNew(profile('x', host: '10.0.0.9'));
      await store.activate(saved.id);

      expect(store.activeBaseUrl, 'http://10.0.0.9:6191');
    });

    test('ตรวจแล้วประกาศสองครั้ง คือกำลังตรวจ และผลลัพธ์', () async {
      final store = newStore();
      await store.load();
      final states = <ServerStatus>[];
      store.addListener(() => states.add(store.status));

      await store.refreshStatus(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'service': 'WMS', 'ok': true}), 200),
        ),
      );

      // ต้องเห็น checking ด้วย ไม่งั้นผู้ใช้กดปุ่มแล้วเหมือนไม่มีอะไรเกิดขึ้น
      expect(states, [ServerStatus.checking, ServerStatus.connected]);
    });

    test('เซิร์ฟเวอร์ตอบ HTML ต้องขึ้นว่าไม่ได้เชื่อมต่อ', () async {
      final store = newStore();
      await store.load();

      await store.refreshStatus(
        client: MockClient((_) async => http.Response('<html></html>', 200)),
      );

      expect(store.status, ServerStatus.disconnected);
      expect(store.lastResult?.message, contains('Base Path'));
    });
  });
}
