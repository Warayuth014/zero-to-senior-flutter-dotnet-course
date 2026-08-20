import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/core/api_client.dart';
import 'package:flutter_wms_companion/core/api_failure.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// สร้าง ApiClient ที่ตอบตามที่เรากำหนด โดยไม่ต้องมี server จริง
///
/// [onRequest] เก็บคำขอที่ถูกส่งไว้ให้ตรวจได้ — เพราะบั๊กจำนวนมาก
/// อยู่ที่ "ส่งอะไรไป" ไม่ใช่ "แปลผลอย่างไร"
ApiClient clientThatReturns(
  http.Response Function(http.Request request) respond, {
  void Function(http.Request request)? onRequest,
  String baseUrl = 'http://wms.local:5000',
}) => ApiClient(
  baseUrl: baseUrl,
  client: MockClient((request) async {
    onRequest?.call(request);
    return respond(request);
  }),
);

http.Response jsonResponse(Object? body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  group('คำขอที่ส่งออกไป', () {
    test('GET ส่งไปที่ path ที่ถูกต้องและมี Content-Type', () async {
      http.Request? sent;
      final api = clientThatReturns(
        (_) => jsonResponse({'items': <Object>[]}, 200),
        onRequest: (request) => sent = request,
      );

      await api.getJson('/api/WMS/mobile_tasks');

      expect(sent!.method, 'GET');
      expect(sent!.url.path, '/api/WMS/mobile_tasks');
      expect(sent!.headers['Content-Type'], contains('application/json'));
    });

    test('ยังไม่ได้เข้าสู่ระบบ ต้องไม่มี Authorization ติดไป', () async {
      http.Request? sent;
      final api = clientThatReturns(
        (_) => jsonResponse(const <String, Object>{}, 200),
        onRequest: (request) => sent = request,
      );

      await api.getJson('/api/WMS/mobile_tasks');

      expect(sent!.headers.containsKey('Authorization'), isFalse);
    });

    test('เข้าสู่ระบบแล้วต้องแนบ token และอ่านค่าล่าสุดทุกครั้ง', () async {
      final tokens = <String?>[];
      final api = clientThatReturns(
        (_) => jsonResponse(const <String, Object>{}, 200),
        onRequest: (request) => tokens.add(request.headers['Authorization']),
      )..authToken = 'token-คนแรก';

      await api.getJson('/api/WMS/mobile_tasks');

      // จำลองการออกจากระบบ — คำขอถัดไปต้องไม่มี token เก่าติดไป
      api.authToken = null;
      await api.getJson('/api/WMS/mobile_tasks');

      expect(tokens, ['Bearer token-คนแรก', null]);
    });

    test('POST ส่ง body เป็น JSON และแนบ header เพิ่มที่ส่งเข้ามา', () async {
      http.Request? sent;
      final api = clientThatReturns(
        (_) => jsonResponse(const <String, Object>{}, 200),
        onRequest: (request) => sent = request,
      );

      await api.postJson(
        '/api/WMS/mobile_tasks/T-001/complete',
        const {'quantity': 12},
        headers: {'Idempotency-Key': 'cmd-8821'},
      );

      expect(sent!.method, 'POST');
      expect(jsonDecode(sent!.body), {'quantity': 12});
      expect(sent!.headers['Idempotency-Key'], 'cmd-8821');
    });
  });

  group('คำตอบที่สำเร็จ', () {
    test('อ่าน JSON ที่เป็นภาษาไทยได้ถูกต้อง', () async {
      final api = clientThatReturns(
        (_) => jsonResponse({'supplierName': 'บริษัท ซัพพลาย จำกัด'}, 200),
      );

      final json = await api.getJson('/api/WMS/inbound');

      expect(json['supplierName'], 'บริษัท ซัพพลาย จำกัด');
    });

    test('204 ที่ไม่มีเนื้อหา ถือว่าสำเร็จ ไม่ใช่พัง', () async {
      final api = clientThatReturns((_) => http.Response('', 204));

      final json = await api.postJson('/api/WMS/ping', const {});

      expect(json, isEmpty);
    });
  });

  group('คำตอบที่ล้มเหลว', () {
    test('อ่าน ProblemDetails แล้วใช้ detail เป็นข้อความให้ผู้ใช้', () async {
      final api = clientThatReturns(
        (_) => jsonResponse({
          'title': 'Conflict',
          'status': 409,
          'detail': 'งานนี้ถูกปิดโดยผู้ใช้อื่นแล้ว',
          'traceId': '00-abc-123',
        }, 409),
      );

      await expectLater(
        api.postJson('/api/WMS/mobile_tasks/T-001/complete', const {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiFailureKind.conflict)
              .having((e) => e.statusCode, 'statusCode', 409)
              .having(
                (e) => e.userMessage,
                'userMessage',
                'งานนี้ถูกปิดโดยผู้ใช้อื่นแล้ว',
              )
              .having((e) => e.problem?.traceId, 'traceId', '00-abc-123'),
        ),
      );
    });

    test('ข้อผิดพลาดรายช่องจาก 400 ต้องอ่านมาแสดงได้', () async {
      final api = clientThatReturns(
        (_) => jsonResponse({
          'title': 'One or more validation errors occurred.',
          'status': 400,
          'errors': {
            'quantity': ['จำนวนต้องมากกว่าศูนย์'],
          },
        }, 400),
      );

      await expectLater(
        api.postJson('/api/WMS/mobile_tasks/T-001/complete', const {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiFailureKind.validation)
              .having(
                (e) => e.userMessage,
                'userMessage',
                contains('จำนวนต้องมากกว่าศูนย์'),
              ),
        ),
      );
    });

    test('401 กับ 403 ต้องแยกชนิดกัน', () async {
      final unauthorized = clientThatReturns((_) => http.Response('', 401));
      final forbidden = clientThatReturns((_) => http.Response('', 403));

      await expectLater(
        unauthorized.getJson('/api/WMS/mobile_tasks'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.unauthorized,
          ),
        ),
      );
      await expectLater(
        forbidden.getJson('/api/WMS/mobile_tasks'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.forbidden,
          ),
        ),
      );
    });

    test('ได้ HTML แทน JSON ต้องไม่พังแบบอธิบายไม่ได้', () async {
      // เกิดจริงเมื่อตัวกลางในเครือข่ายคืนหน้าเข้าสู่ระบบขององค์กร
      final api = clientThatReturns(
        (_) => http.Response('<html><body>Login</body></html>', 500),
      );

      await expectLater(
        api.getJson('/api/WMS/mobile_tasks'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiFailureKind.server)
              .having((e) => e.statusCode, 'statusCode', 500),
        ),
      );
    });
  });

  group('เชื่อมต่อไม่ได้', () {
    test('GET ที่เน็ตหลุด รู้แน่ว่าไม่มีอะไรเกิดขึ้น', () async {
      final api = ApiClient(
        baseUrl: 'http://wms.local',
        client: MockClient((_) async => throw const SocketException('ไม่มีเส้นทาง')),
      );

      await expectLater(
        api.getJson('/api/WMS/mobile_tasks'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiFailureKind.network)
              .having((e) => e.outcomeUnknown, 'outcomeUnknown', isFalse),
        ),
      );
    });

    test('POST ที่เน็ตหลุด ไม่รู้ว่า server ทำไปแล้วหรือยัง', () async {
      final api = ApiClient(
        baseUrl: 'http://wms.local',
        client: MockClient((_) async => throw const SocketException('ไม่มีเส้นทาง')),
      );

      await expectLater(
        api.postJson('/api/WMS/mobile_tasks/T-001/complete', const {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.kind, 'kind', ApiFailureKind.network)
              .having((e) => e.outcomeUnknown, 'outcomeUnknown', isTrue),
        ),
      );
    });
  });
}
