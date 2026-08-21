import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet_failure.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet_repository.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet_screen_v1.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet_screen_v2.dart';
import 'package:flutter_wms_companion/architecture_lab/pallet_store.dart';
import 'package:flutter_wms_companion/core/api_client.dart';
import 'package:flutter_wms_companion/json_basics/json_read.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const String baseUrl = 'http://localhost:5000';

String zoneBody(List<Map<String, Object?>> items) =>
    jsonEncode({'items': items});

Map<String, Object?> palletJson(
  String code, {
  String productCode = 'P-100',
  int quantity = 12,
  bool onHold = false,
}) => {
  'code': code,
  'productCode': productCode,
  'quantity': quantity,
  'onHold': onHold,
};

void main() {
  // -------------------------------------------------------------------------
  // ส่วนที่ 1 — พฤติกรรมที่ผู้ใช้เห็น ต้องเหมือนกันทั้งก่อนและหลังแยกชั้น
  //
  // นี่คือนิยามของคำว่า refactor: เปลี่ยนโครงข้างในโดยที่ข้างนอกเหมือนเดิม
  // ถ้าเทสต์ชุดนี้ผ่านทั้งสองรุ่น แปลว่าเราย้ายโค้ด ไม่ได้เขียนแอปใหม่ (9.16)
  // -------------------------------------------------------------------------
  group('พฤติกรรมเดียวกัน · รุ่นรวมทุกอย่างไว้ในจอ', () {
    runSharedBehaviourTests(
      (client) => PalletScreenV1(client: client, zone: 'A1'),
    );
  });

  group('พฤติกรรมเดียวกัน · รุ่นแยกชั้น', () {
    runSharedBehaviourTests((client) {
      final api = ApiClient(baseUrl: baseUrl, client: client);
      final store = PalletStore(RemotePalletRepository(api));
      return PalletScreenV2(store: store, zone: 'A1');
    });
  });

  // -------------------------------------------------------------------------
  // ส่วนที่ 2 — สิ่งที่ทำได้เพิ่มหลังแยกชั้น
  //
  // ทุกเทสต์ในส่วนนี้ไม่สร้าง widget แม้แต่ตัวเดียว รุ่นรวมทุกอย่างไว้ในจอ
  // เขียนเทสต์แบบนี้ไม่ได้เลย เพราะกฎอยู่ใน State ที่เข้าถึงจากข้างนอกไม่ได้
  // -------------------------------------------------------------------------
  group('repository ทดสอบได้เดี่ยว ๆ', () {
    test('แปล 409 เป็นข้อความของเซิร์ฟเวอร์ ไม่ใช่เลข status', () async {
      final repository = RemotePalletRepository(
        ApiClient(
          baseUrl: baseUrl,
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({'detail': 'พาเลทนี้ถูกล็อกโดยสมชายอยู่'}),
              409,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      );

      final failure = await repository
          .hold('PLT-001', commandId: 'cmd-1')
          .then<PalletFailure?>((_) => null)
          .onError<PalletFailure>((error, _) => error);

      expect(failure?.message, 'พาเลทนี้ถูกล็อกโดยสมชายอยู่');
      // ผู้ใช้กดลองใหม่ไปก็ได้ผลเดิม จนกว่าสมชายจะปลดล็อก
      expect(failure?.canRetry, isFalse);
    });

    test('แปลเน็ตหลุดเป็นข้อความที่บอกให้ลองใหม่ได้', () async {
      final repository = RemotePalletRepository(
        ApiClient(
          baseUrl: baseUrl,
          client: MockClient((_) async => throw http.ClientException('offline')),
        ),
      );

      await expectLater(
        repository.fetchInZone('A1'),
        throwsA(
          isA<PalletFailure>().having((f) => f.canRetry, 'canRetry', isTrue),
        ),
      );
    });

    test('ข้อมูลผิดสัญญาต้องโยน ContractException พร้อมตำแหน่ง', () async {
      final repository = RemotePalletRepository(
        ApiClient(
          baseUrl: baseUrl,
          client: MockClient(
            (_) async => http.Response(
              zoneBody([
                palletJson('PLT-001'),
                // 1.5 ชิ้นไม่มีอยู่จริงในคลัง — ปัดเศษเงียบ ๆ คือของหาย (6.7)
                palletJson('PLT-002')..['quantity'] = 1.5,
              ]),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            ),
          ),
        ),
      );

      // ไม่ถูกกลืนเป็น PalletFailure เพราะผู้ใช้ทำอะไรกับมันไม่ได้ ทีมต้องแก้
      await expectLater(
        repository.fetchInZone('A1'),
        throwsA(
          isA<ContractException>().having(
            (e) => e.path,
            'path',
            'items[1].quantity',
          ),
        ),
      );
    });
  });

  group('store ทดสอบได้เดี่ยว ๆ', () {
    test('คำตอบของคำขอเก่าที่กลับมาช้า ต้องไม่ทับคำตอบใหม่', () async {
      final repository = _ScriptedRepository();
      final store = PalletStore(repository);

      final first = store.load('A1');
      final second = store.load('B2');

      // ตอบคำขอที่สองก่อน แล้วค่อยตอบคำขอแรก — สลับลำดับตั้งใจ
      repository.completeAt(1, [const Pallet(
        code: 'PLT-B2',
        productCode: 'P-2',
        quantity: 1,
        onHold: false,
      )]);
      await second;
      repository.completeAt(0, [const Pallet(
        code: 'PLT-A1',
        productCode: 'P-1',
        quantity: 1,
        onHold: false,
      )]);
      await first;

      expect(store.pallets.single.code, 'PLT-B2');
      expect(store.zone, 'B2');
    });

    test('กดล็อกซ้ำระหว่างรอ ต้องยิงคำสั่งครั้งเดียว', () async {
      final repository = _ScriptedRepository();
      final store = PalletStore(repository);
      const pallet = Pallet(
        code: 'PLT-001',
        productCode: 'P-1',
        quantity: 5,
        onHold: false,
      );

      final firstTap = store.hold(pallet);
      final secondTap = store.hold(pallet);

      expect(repository.holdCalls, 1);
      repository.completeHold(pallet.copyWith(onHold: true));
      await Future.wait([firstTap, secondTap]);

      expect(repository.holdCalls, 1);
      expect(store.isBusy(pallet.code), isFalse);
    });

    test('ล็อกสำเร็จแล้วแทนที่เฉพาะแถวนั้น ไม่โหลดใหม่ทั้งหน้า', () async {
      final repository = _ScriptedRepository();
      final store = PalletStore(repository);

      final loading = store.load('A1');
      repository.completeAt(0, const [
        Pallet(code: 'PLT-001', productCode: 'P-1', quantity: 5, onHold: false),
        Pallet(code: 'PLT-002', productCode: 'P-2', quantity: 7, onHold: false),
      ]);
      await loading;

      final holding = store.hold(store.pallets.first);
      repository.completeHold(store.pallets.first.copyWith(onHold: true));
      await holding;

      expect(store.pallets.first.onHold, isTrue);
      expect(store.pallets.last.onHold, isFalse);
      expect(repository.fetchCalls, 1);
    });
  });
}

/// เทสต์ชุดเดียวกันที่รันกับทั้งสองรุ่น
///
/// รับ builder ที่แปลง http.Client เป็นหน้าจอ เพราะสองรุ่นประกอบของไม่เหมือนกัน
/// แต่จุดที่ของปลอมเข้าไปคือจุดเดียวกัน
void runSharedBehaviourTests(Widget Function(http.Client client) build) {
  Widget wrap(http.Client client) => MaterialApp(home: build(client));

  MockClient jsonClient(int statusCode, String body) => MockClient(
    (_) async => http.Response(
      body,
      statusCode,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );

  testWidgets('โหลดสำเร็จแล้วเห็นรายการพาเลท', (tester) async {
    await tester.pumpWidget(
      wrap(
        jsonClient(200, zoneBody([palletJson('PLT-001'), palletJson('PLT-002')])),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pallet-PLT-001')), findsOneWidget);
    expect(find.byKey(const Key('pallet-PLT-002')), findsOneWidget);
  });

  testWidgets('ระหว่างโหลดครั้งแรกเห็นวงหมุน', (tester) async {
    final gate = Completer<http.Response>();
    await tester.pumpWidget(
      wrap(MockClient((_) => gate.future)),
    );
    await tester.pump();

    expect(find.byKey(const Key('initial-loading')), findsOneWidget);

    gate.complete(
      http.Response(
        zoneBody([palletJson('PLT-001')]),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('โซนที่ไม่มีพาเลทเห็นข้อความว่าง ไม่ใช่หน้าจอเปล่า', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(jsonClient(200, zoneBody([]))));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-text')), findsOneWidget);
  });

  testWidgets('เซิร์ฟเวอร์พังเห็นข้อความและปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(wrap(jsonClient(500, '{}')));
    await tester.pumpAndSettle();

    expect(
      find.text('เซิร์ฟเวอร์มีปัญหา แจ้งทีมระบบถ้ายังไม่หาย'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-button')), findsOneWidget);
  });

  testWidgets('เน็ตหลุดเห็นข้อความและปุ่มลองใหม่', (tester) async {
    await tester.pumpWidget(
      wrap(MockClient((_) async => throw http.ClientException('offline'))),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสัญญาณแล้วลองใหม่'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry-button')), findsOneWidget);
  });

  testWidgets('ล็อกพาเลทสำเร็จแล้วแถวนั้นเปลี่ยนเป็นล็อกแล้ว', (tester) async {
    final client = MockClient((request) async {
      final body = request.method == 'POST'
          ? jsonEncode(palletJson('PLT-001', onHold: true))
          : zoneBody([palletJson('PLT-001')]);
      return http.Response(
        body,
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

    await tester.pumpWidget(wrap(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hold-PLT-001')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hold-PLT-001')), findsNothing);
    expect(find.text('ล็อกแล้ว'), findsOneWidget);
  });

  testWidgets('กดล็อกรัว ๆ ต้องส่งคำสั่งไปครั้งเดียว', (tester) async {
    var postCount = 0;
    final gate = Completer<http.Response>();
    final client = MockClient((request) {
      if (request.method == 'POST') {
        postCount++;
        return gate.future;
      }
      return Future.value(
        http.Response(
          zoneBody([palletJson('PLT-001')]),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      );
    });

    await tester.pumpWidget(wrap(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('hold-PLT-001')));
    await tester.pump();
    // ปุ่มถูก disable แล้ว แต่ยิง tap ซ้ำที่ตำแหน่งเดิมเพื่อจำลองการกดรัว
    await tester.tap(find.byKey(const Key('hold-PLT-001')), warnIfMissed: false);
    await tester.pump();

    expect(postCount, 1);

    gate.complete(
      http.Response(
        jsonEncode(palletJson('PLT-001', onHold: true)),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    await tester.pumpAndSettle();
  });
}

/// repository ปลอมที่คุมได้ว่าจะตอบเมื่อไหร่
///
/// สร้างได้เพราะมี interface ให้ implement — รุ่นรวมทุกอย่างไว้ในจอไม่มีที่ให้
/// ของปลอมเข้าไปนอกจากระดับ http (9.5)
class _ScriptedRepository implements PalletRepository {
  final List<Completer<List<Pallet>>> _fetches = [];
  final List<Completer<Pallet>> _holds = [];

  int get fetchCalls => _fetches.length;
  int get holdCalls => _holds.length;

  @override
  Future<List<Pallet>> fetchInZone(String zone) {
    final completer = Completer<List<Pallet>>();
    _fetches.add(completer);
    return completer.future;
  }

  @override
  Future<Pallet> hold(String code, {required String commandId}) {
    final completer = Completer<Pallet>();
    _holds.add(completer);
    return completer.future;
  }

  void completeAt(int index, List<Pallet> pallets) =>
      _fetches[index].complete(pallets);

  void completeHold(Pallet pallet) => _holds.last.complete(pallet);
}
