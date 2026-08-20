import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/core/api_client.dart';
import 'package:flutter_wms_companion/core/api_failure.dart';
import 'package:flutter_wms_companion/core/api_log.dart';
import 'package:flutter_wms_companion/core/api_retry.dart';

void main() {
  group('แปลงรหัสตอบกลับเป็นชนิดความล้มเหลว', () {
    test('รหัสที่รู้จักต้องแยกชนิดได้ถูก', () {
      expect(failureKindForStatus(401), ApiFailureKind.unauthorized);
      expect(failureKindForStatus(403), ApiFailureKind.forbidden);
      expect(failureKindForStatus(404), ApiFailureKind.notFound);
      expect(failureKindForStatus(409), ApiFailureKind.conflict);
      expect(failureKindForStatus(400), ApiFailureKind.validation);
      expect(failureKindForStatus(422), ApiFailureKind.validation);
      expect(failureKindForStatus(500), ApiFailureKind.server);
      expect(failureKindForStatus(503), ApiFailureKind.server);
    });

    test('รหัสที่ไม่ควรมาถึงตรงนี้ ถือว่าผิดสัญญา', () {
      expect(failureKindForStatus(418), ApiFailureKind.contract);
    });
  });

  group('ลองใหม่ได้หรือไม่', () {
    test('เฉพาะเน็ต หมดเวลา และ server ขัดข้อง ที่ลองใหม่แล้วมีความหมาย', () {
      expect(ApiFailureKind.network.isRetryable, isTrue);
      expect(ApiFailureKind.timeout.isRetryable, isTrue);
      expect(ApiFailureKind.server.isRetryable, isTrue);
    });

    test('สิทธิ์ ความขัดแย้ง และข้อมูลผิด ลองใหม่ไปก็ได้ผลเดิม', () {
      expect(ApiFailureKind.unauthorized.isRetryable, isFalse);
      expect(ApiFailureKind.forbidden.isRetryable, isFalse);
      expect(ApiFailureKind.conflict.isRetryable, isFalse);
      expect(ApiFailureKind.validation.isRetryable, isFalse);
      expect(ApiFailureKind.notFound.isRetryable, isFalse);
      expect(ApiFailureKind.contract.isRetryable, isFalse);
    });

    test('เน็ตและหมดเวลาคือกรณีที่ไม่รู้ผล ส่วนที่เหลือรู้แน่', () {
      expect(ApiFailureKind.network.outcomeIsKnown, isFalse);
      expect(ApiFailureKind.timeout.outcomeIsKnown, isFalse);
      expect(ApiFailureKind.conflict.outcomeIsKnown, isTrue);
      expect(ApiFailureKind.validation.outcomeIsKnown, isTrue);
    });
  });

  group('ProblemDetails', () {
    test('อ่าน detail และ title ได้ และ detail สำคัญกว่า', () {
      final problem = ProblemDetails.tryParse(const {
        'type': 'https://httpstatuses.io/409',
        'title': 'Conflict',
        'status': 409,
        'detail': 'งานนี้ถูกปิดโดยผู้ใช้อื่นแล้ว',
        'traceId': '00-abc-123',
      });

      expect(problem, isNotNull);
      expect(problem!.status, 409);
      expect(problem.traceId, '00-abc-123');
      expect(problem.userMessage, 'งานนี้ถูกปิดโดยผู้ใช้อื่นแล้ว');
    });

    test('มีแต่ title ก็ใช้ title', () {
      final problem = ProblemDetails.tryParse(const {'title': 'Not Found'});
      expect(problem!.userMessage, 'Not Found');
    });

    test('ข้อผิดพลาดรายช่องต้องถูกรวมมาแสดงได้', () {
      final problem = ProblemDetails.tryParse(const {
        'title': 'One or more validation errors occurred.',
        'status': 400,
        'errors': {
          'quantity': ['จำนวนต้องมากกว่าศูนย์'],
          'palletCode': ['รูปแบบรหัสพาเลทไม่ถูกต้อง'],
        },
      });

      expect(problem!.hasFieldErrors, isTrue);
      expect(problem.errors['quantity'], ['จำนวนต้องมากกว่าศูนย์']);
      // ข้อผิดพลาดรายช่องสำคัญกว่า title กว้าง ๆ
      expect(problem.userMessage, contains('จำนวนต้องมากกว่าศูนย์'));
      expect(problem.userMessage, contains('รูปแบบรหัสพาเลทไม่ถูกต้อง'));
    });

    test('JSON ที่ไม่ใช่ ProblemDetails ต้องคืน null ไม่ใช่โยน', () {
      expect(ProblemDetails.tryParse(const {'items': []}), isNull);
      expect(ProblemDetails.tryParse(null), isNull);
    });

    test('ค่าว่างและช่องว่างล้วน ไม่นับว่ามีข้อความ', () {
      final problem = ProblemDetails.tryParse(const {
        'title': '   ',
        'detail': '',
        'errors': {'quantity': []},
      });

      expect(problem, isNotNull);
      expect(problem!.userMessage, isNull);
      expect(problem.hasFieldErrors, isFalse);
    });
  });

  group('ข้อความที่แสดงให้ผู้ใช้', () {
    test('ใช้สิ่งที่ server บอกก่อนข้อความกลางของเรา', () {
      const exception = ApiException(
        'HTTP 409',
        statusCode: 409,
        kind: ApiFailureKind.conflict,
        problem: ProblemDetails(detail: 'งานนี้ถูกปิดไปแล้ว'),
      );

      expect(exception.userMessage, 'งานนี้ถูกปิดไปแล้ว');
    });

    test('ไม่มีรายละเอียดจาก server จึงใช้ข้อความกลาง', () {
      const exception = ApiException(
        'เชื่อมต่อ server ไม่ได้',
        kind: ApiFailureKind.network,
      );

      expect(exception.userMessage, 'เชื่อมต่อ server ไม่ได้');
    });
  });

  group('การลองใหม่', () {
    test('ล้มเหลวแบบลองใหม่ได้ ต้องยิงจนกว่าจะสำเร็จ', () async {
      final delays = <Duration>[];
      final policy = RetryPolicy(
        sleep: (duration) async => delays.add(duration),
        random: _FixedRandom(),
      );

      var attempts = 0;
      final result = await policy.run(
        () async {
          attempts++;
          if (attempts < 3) {
            throw const ApiException('ล่ม', kind: ApiFailureKind.server);
          }
          return 'ok';
        },
        isIdempotent: true,
      );

      expect(result, 'ok');
      expect(attempts, 3);
      expect(delays, hasLength(2));
    });

    test('ยืดระยะขึ้นทุกครั้งที่ล้มเหลว', () async {
      final delays = <Duration>[];
      final policy = RetryPolicy(
        maxAttempts: 4,
        baseDelay: const Duration(milliseconds: 100),
        sleep: (duration) async => delays.add(duration),
        random: _FixedRandom(),
      );

      await expectLater(
        policy.run(
          () async => throw const ApiException(
            'ล่ม',
            kind: ApiFailureKind.server,
          ),
          isIdempotent: true,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(delays.map((d) => d.inMilliseconds), [100, 200, 400]);
    });

    test('ยืดได้ไม่เกินเพดาน', () {
      final policy = RetryPolicy(
        baseDelay: const Duration(seconds: 1),
        maxDelay: const Duration(seconds: 3),
        random: _FixedRandom(),
      );

      expect(policy.delayForAttempt(10).inMilliseconds, 3000);
    });

    test('ล้มเหลวแบบลองใหม่ไม่ได้ ต้องยิงครั้งเดียวแล้วโยนต่อ', () async {
      final policy = RetryPolicy(
        sleep: (duration) async {},
        random: _FixedRandom(),
      );

      var attempts = 0;
      await expectLater(
        policy.run(
          () async {
            attempts++;
            throw const ApiException(
              'ไม่มีสิทธิ์',
              kind: ApiFailureKind.forbidden,
            );
          },
          isIdempotent: true,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(attempts, 1);
    });

    test('คำสั่งที่ไม่ปลอดภัยต่อการยิงซ้ำ ห้ามลองใหม่เอง', () async {
      final policy = RetryPolicy(
        sleep: (duration) async {},
        random: _FixedRandom(),
      );

      var attempts = 0;
      await expectLater(
        policy.run(
          () async {
            attempts++;
            throw const ApiException(
              'server ไม่ตอบหลังส่งคำสั่ง',
              kind: ApiFailureKind.timeout,
              outcomeUnknown: true,
            );
          },
          isIdempotent: false,
        ),
        throwsA(isA<ApiException>()),
      );

      expect(attempts, 1);
    });
  });

  group('การบันทึกที่ปลอดภัย', () {
    test('ปิดค่า token ใน URL แต่เก็บชื่อคีย์ไว้', () {
      final uri = Uri.parse(
        'http://wms.local/api/tasks?search=PAL-01&token=secret123',
      );

      final redacted = redactUri(uri);

      expect(redacted, contains('search=PAL-01'));
      // ใช้ตัวอักษรล้วนเป็นเครื่องหมายปิด เพราะ Uri encode สัญลักษณ์
      expect(redacted, contains('token=REDACTED'));
      expect(redacted, isNot(contains('secret123')));
    });

    test('ปิดค่า header ที่อ่อนไหว ไม่สนตัวพิมพ์', () {
      final headers = redactHeaders({
        'Authorization': 'Bearer eyJhbGciOi...',
        'Content-Type': 'application/json',
      });

      expect(headers['Authorization'], 'REDACTED');
      expect(headers['Content-Type'], 'application/json');
    });

    test('สรุปคำขอต้องมีข้อมูลพอไล่หาสาเหตุ โดยไม่มี body', () {
      final line = describeExchange(
        method: 'POST',
        uri: Uri.parse('http://wms.local/api/tasks/T-001/complete'),
        statusCode: 409,
        elapsed: const Duration(milliseconds: 812),
        traceId: '00-abc-123',
      );

      expect(line, contains('POST'));
      expect(line, contains('409'));
      expect(line, contains('812 ms'));
      expect(line, contains('trace=00-abc-123'));
    });

    test('ไม่ได้คำตอบก็ยังบันทึกได้', () {
      final line = describeExchange(
        method: 'GET',
        uri: Uri.parse('http://wms.local/api/tasks'),
        statusCode: null,
        elapsed: const Duration(seconds: 15),
      );

      expect(line, contains('ไม่ได้คำตอบ'));
    });
  });
}

/// สุ่มที่ไม่สุ่ม เพื่อให้เทสต์ได้ผลเหมือนเดิมทุกครั้ง
class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}
