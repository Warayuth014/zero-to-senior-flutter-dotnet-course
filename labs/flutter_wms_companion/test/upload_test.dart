import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_wms_companion/core/api_failure.dart';
import 'package:flutter_wms_companion/upload_lab/image_validation.dart';
import 'package:flutter_wms_companion/upload_lab/picked_image.dart';
import 'package:flutter_wms_companion/upload_lab/upload_client.dart';
import 'package:flutter_wms_companion/upload_lab/upload_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// สร้างไบต์ที่ขึ้นต้นด้วยลายเซ็นของ JPEG จริง
Uint8List jpegBytes({int size = 100 * 1024}) {
  final bytes = Uint8List(size);
  bytes[0] = 0xFF;
  bytes[1] = 0xD8;
  bytes[2] = 0xFF;
  return bytes;
}

Uint8List pngBytes({int size = 100 * 1024}) {
  final bytes = Uint8List(size);
  bytes[0] = 0x89;
  bytes[1] = 0x50;
  bytes[2] = 0x4E;
  bytes[3] = 0x47;
  return bytes;
}

PickedImage image({
  Uint8List? bytes,
  String fileName = 'IMG_0001.jpg',
  String mimeType = 'image/jpeg',
  int? width = 1024,
  int? height = 1024,
}) => PickedImage(
  bytes: bytes ?? jpegBytes(),
  fileName: fileName,
  mimeType: mimeType,
  width: width,
  height: height,
);

/// อ่าน body ของ multipart เป็นข้อความ
///
/// ใช้ latin1 ไม่ใช่ utf8 เพราะ body มีไบต์ดิบของรูปปนอยู่ ซึ่งไม่ใช่ UTF-8
/// ที่ถูกต้อง — `request.body` จะโยน FormatException ทันที
/// latin1 แปลงทีละไบต์เป็นตัวอักษร จึงค้นข้อความ ASCII ในนั้นได้
String multipartText(http.Request request) => latin1.decode(request.bodyBytes);

void main() {
  group('ตรวจรูปก่อนส่ง', () {
    test('รูปที่ถูกต้องผ่าน', () {
      expect(checkImage(image()), isA<ImageAccepted>());
    });

    test('ชนิดที่ไม่รองรับถูกปฏิเสธ พร้อมบอกว่ารองรับอะไร', () {
      final result = checkImage(
        image(mimeType: 'image/heic', bytes: jpegBytes()),
      );
      expect(result, isA<ImageRejected>());
      expect((result as ImageRejected).message, contains('JPG'));
    });

    test('ไฟล์ใหญ่เกินถูกปฏิเสธ พร้อมบอกขนาดจริง', () {
      final result = checkImage(image(bytes: jpegBytes(size: 8 * 1024 * 1024)));
      expect(result, isA<ImageRejected>());
      // บอกทั้งขนาดที่ได้และขนาดที่รับได้ ผู้ใช้จะได้รู้ว่าต้องลดแค่ไหน
      expect((result as ImageRejected).message, contains('8.0 MB'));
      expect(result.message, contains('5 MB'));
    });

    test('ไฟล์เล็กผิดปกติถูกปฏิเสธ', () {
      expect(
        checkImage(image(bytes: jpegBytes(size: 1024))),
        isA<ImageRejected>(),
      );
    });

    test('เนื้อไฟล์ไม่ตรงกับชนิดที่อ้าง ถูกจับได้', () {
      // ไฟล์ PNG ที่ถูกเปลี่ยนนามสกุลและ mimeType เป็น jpeg
      final result = checkImage(image(bytes: pngBytes(), mimeType: 'image/jpeg'));
      expect(result, isA<ImageRejected>());
      expect((result as ImageRejected).message, contains('เนื้อไฟล์'));
    });

    test('PNG จริงผ่าน', () {
      expect(
        checkImage(image(bytes: pngBytes(), mimeType: 'image/png')),
        isA<ImageAccepted>(),
      );
    });

    test('รูปเล็กกว่าที่แนะนำ ได้คำเตือน ไม่ใช่ถูกห้าม', () {
      // ห้ามเฉพาะสิ่งที่ผิดแน่นอน รูปเบลอยังใช้เป็นหลักฐานได้ถ้าผู้ใช้ยืนยัน
      final result = checkImage(image(width: 200, height: 200));
      expect(result, isA<ImageWarning>());
      expect((result as ImageWarning).message, contains('200×200'));
    });

    test('ไม่รู้ขนาดพิกเซล ก็ยังผ่านได้', () {
      expect(checkImage(image(width: null, height: null)), isA<ImageAccepted>());
    });
  });

  group('ชื่อไฟล์ที่ปลอดภัย', () {
    test('ตัดเส้นทางทิ้ง', () {
      expect(
        safeFileName('../../etc/passwd', extension: 'jpg'),
        'passwd.jpg',
      );
      expect(
        safeFileName(r'C:\Users\x\photo.jpg', extension: 'jpg'),
        'photo.jpg',
      );
    });

    test('แทนอักขระที่ไม่ปลอดภัย', () {
      expect(safeFileName('รูป สินค้า#1.jpg', extension: 'jpg'),
          matches(RegExp(r'^[A-Za-z0-9_-]+\.jpg$')));
    });

    test('ชื่อที่เหลือแต่อักขระต้องห้าม ได้ชื่อสำรอง', () {
      expect(safeFileName('###.jpg', extension: 'jpg'), '___.jpg');
      expect(safeFileName('.jpg', extension: 'jpg'), 'image.jpg');
    });

    test('จำกัดความยาว', () {
      final long = 'a' * 200;
      expect(safeFileName('$long.jpg', extension: 'jpg').length, lessThan(70));
    });

    test('ใช้นามสกุลจาก mimeType ไม่ใช่จากชื่อเดิม', () {
      // ไฟล์ชื่อ .exe แต่เนื้อเป็น png ต้องได้ .png
      expect(safeFileName('malware.exe', extension: 'png'), 'malware.png');
    });
  });

  group('UploadClient', () {
    test('ส่งเป็น multipart พร้อมช่องและไฟล์', () async {
      String? body;
      String? contentType;

      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((request) async {
          body = multipartText(request);
          contentType = request.headers['content-type'];
          return http.Response(jsonEncode({'url': '/uploads/a.jpg'}), 200);
        }),
      );

      final outcome = await client.uploadImage(
        path: '/api/WMS/mobile_upload',
        image: image(),
        commandId: 'cmd-1',
        fields: {'partId': 'P-100', 'station': 'PDA'},
      );

      expect(outcome, isA<UploadSucceeded>());
      // boundary ถูกสร้างโดย MultipartRequest ห้ามตั้ง Content-Type เอง
      expect(contentType, contains('multipart/form-data'));
      expect(contentType, contains('boundary='));
      expect(body, contains('name="partId"'));
      expect(body, contains('P-100'));
      expect(body, contains('name="file"'));
      expect(body, contains('filename='));
    });

    test('แนบ Idempotency-Key และ token', () async {
      Map<String, String>? headers;
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((request) async {
          headers = request.headers;
          return http.Response(jsonEncode({'url': '/a.jpg'}), 200);
        }),
      )..authToken = 'tok-123';

      await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-42',
      );

      expect(headers!['Idempotency-Key'], 'cmd-42');
      expect(headers!['Authorization'], 'Bearer tok-123');
    });

    test('ชื่อไฟล์ที่ส่งไปถูกทำให้ปลอดภัยแล้ว', () async {
      String? body;
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((request) async {
          body = multipartText(request);
          return http.Response(jsonEncode({'url': '/a.jpg'}), 200);
        }),
      );

      await client.uploadImage(
        path: '/upload',
        image: image(fileName: '../../evil.jpg'),
        commandId: 'cmd-1',
      );

      expect(body, isNot(contains('..')));
      expect(body, contains('evil.jpg'));
    });

    test('รายงานความคืบหน้าจนถึงครบ', () async {
      final progress = <int>[];
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-1',
        onProgress: (sent, total) => progress.add(sent),
      );

      expect(progress, isNotEmpty);
      // ค่าต้องเพิ่มขึ้นเรื่อย ๆ ไม่ถอยหลัง
      for (var i = 1; i < progress.length; i++) {
        expect(progress[i], greaterThanOrEqualTo(progress[i - 1]));
      }
    });

    test('อ่านที่อยู่ไฟล์จากชื่อคีย์ที่เซิร์ฟเวอร์อาจใช้', () async {
      for (final key in ['url', 'imageUrl', 'path', 'location']) {
        final client = UploadClient(
          baseUrl: 'http://localhost:5000',
          client: MockClient(
            (_) async => http.Response(jsonEncode({key: '/uploads/x.jpg'}), 200),
          ),
        );

        final outcome = await client.uploadImage(
          path: '/upload',
          image: image(),
          commandId: 'cmd-1',
        );

        expect(outcome, isA<UploadSucceeded>(), reason: 'คีย์ $key');
        expect((outcome as UploadSucceeded).url, '/uploads/x.jpg');
      }
    });

    test('200 แต่ไม่บอกที่อยู่ไฟล์ ถือว่าผิดสัญญา', () async {
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((_) async => http.Response('{"ok":true}', 200)),
      );

      final outcome = await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-1',
      );

      expect(outcome, isA<UploadFailed>());
      expect((outcome as UploadFailed).kind, ApiFailureKind.contract);
    });

    test('413 บอกให้ลดความละเอียด', () async {
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((_) async => http.Response('', 413)),
      );

      final outcome = await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-1',
      );

      expect(outcome, isA<UploadRejected>());
      expect((outcome as UploadRejected).message, contains('ความละเอียด'));
    });

    test('400 ใช้ข้อความของเซิร์ฟเวอร์', () async {
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'รหัสสินค้านี้ไม่มีอยู่ในระบบ'}),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );

      final outcome = await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-1',
      );

      expect(outcome, isA<UploadRejected>());
      expect((outcome as UploadRejected).message, 'รหัสสินค้านี้ไม่มีอยู่ในระบบ');
    });

    test('เน็ตขาดระหว่างส่ง ต้องบอกว่าไม่รู้ผล', () async {
      final client = UploadClient(
        baseUrl: 'http://localhost:5000',
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      final outcome = await client.uploadImage(
        path: '/upload',
        image: image(),
        commandId: 'cmd-1',
      );

      expect(outcome, isA<UploadFailed>());
      expect((outcome as UploadFailed).outcomeUnknown, isTrue);
    });
  });

  group('UploadStore', () {
    late FakeImagePicker picker;
    late UploadStore store;
    var uploadCalls = 0;
    final commandIds = <String>[];

    UploadClient clientThat(
      Future<http.Response> Function(http.Request request) handler,
    ) => UploadClient(
      baseUrl: 'http://localhost:5000',
      client: MockClient((request) {
        uploadCalls++;
        commandIds.add(request.headers['Idempotency-Key'] ?? '');
        return handler(request);
      }),
    );

    setUp(() {
      uploadCalls = 0;
      commandIds.clear();
      picker = FakeImagePicker(result: image());
    });

    test('เลือกรูปแล้วพร้อมส่ง', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => http.Response('{}', 200)),
      );

      await store.pick(PickSource.camera);

      expect(store.stage, UploadStage.ready);
      expect(store.image, isNotNull);
      expect(picker.lastSource, PickSource.camera);
      expect(store.canUpload, isTrue);
    });

    test('ผู้ใช้กดยกเลิกตอนเลือกรูป ต้องไม่แสดงข้อความผิดพลาด', () async {
      picker.result = null;
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => http.Response('{}', 200)),
      );

      await store.pick(PickSource.gallery);

      expect(store.stage, UploadStage.idle);
      expect(store.message, isNull, reason: 'การยกเลิกไม่ใช่ความผิดพลาด');
    });

    test('ไม่ได้รับสิทธิ์ ต้องบอกทางแก้ ไม่ใช่แค่บอกว่าถูกปฏิเสธ', () async {
      picker.denyPermission = true;
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => http.Response('{}', 200)),
      );

      await store.pick(PickSource.camera);

      expect(store.stage, UploadStage.idle);
      expect(store.message, contains('ตั้งค่า'));
      expect(store.message, contains('กล้อง'));
    });

    test('รูปที่ไม่ผ่านการตรวจ ต้องไม่ถูกส่ง', () async {
      picker.result = image(bytes: jpegBytes(size: 9 * 1024 * 1024));
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => http.Response('{}', 200)),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');

      expect(store.stage, UploadStage.idle);
      expect(uploadCalls, 0, reason: 'ไม่ควรยิงเลย');
    });

    test('รูปที่ได้คำเตือน ยังส่งได้', () async {
      picker.result = image(width: 200, height: 200);
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      expect(store.stage, UploadStage.ready);
      expect(store.warning, isNotNull);

      await store.upload(path: '/upload');
      expect(store.stage, UploadStage.done);
    });

    test('อัปโหลดสำเร็จแล้วเก็บที่อยู่ที่เซิร์ฟเวอร์คืนมา', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/uploads/p1.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload', fields: {'partId': 'P-1'});

      expect(store.stage, UploadStage.done);
      expect(store.uploadedUrl, '/uploads/p1.jpg');
    });

    test('ความคืบหน้าไปถึงเต็มเมื่อเสร็จ', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');

      expect(store.progress, 1.0);
    });

    test('ส่งซ้ำหลังล้มเหลว ต้องใช้รหัสคำสั่งเดิม', () async {
      var attempt = 0;
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async {
          attempt++;
          return attempt == 1
              ? http.Response('', 500)
              : http.Response(jsonEncode({'url': '/a.jpg'}), 200);
        }),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');
      expect(store.stage, UploadStage.failed);

      await store.upload(path: '/upload');
      expect(store.stage, UploadStage.done);

      // รหัสเดิมทั้งสองครั้ง ไม่งั้นเซิร์ฟเวอร์จะเก็บรูปสองใบ
      expect(commandIds, hasLength(2));
      expect(commandIds[0], commandIds[1]);
      expect(commandIds[0], isNotEmpty);
    });

    test('เลือกรูปใหม่ ต้องได้รหัสคำสั่งใหม่', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');
      store.reset();
      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');

      expect(commandIds[0], isNot(commandIds[1]));
    });

    test('เน็ตขาด ต้องเตือนให้ตรวจก่อนส่งซ้ำ', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => throw http.ClientException('offline')),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');

      expect(store.stage, UploadStage.failed);
      expect(store.message, contains('ตรวจว่ารูปขึ้นแล้วหรือยัง'));
    });

    test('เซิร์ฟเวอร์ปฏิเสธรูป ต้องล้างรูปทิ้งให้เลือกใหม่', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat((_) async => http.Response('', 413)),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');

      // กดส่งซ้ำไม่ช่วย ต้องเลือกรูปใหม่ จึงล้างของเก่าทิ้ง
      expect(store.stage, UploadStage.idle);
      expect(store.image, isNull);
      expect(store.message, isNotNull);
    });

    test('กดส่งซ้ำระหว่างที่กำลังส่ง ต้องไม่ยิงซ้ำ', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      final first = store.upload(path: '/upload');
      final second = store.upload(path: '/upload');
      await Future.wait([first, second]);

      expect(uploadCalls, 1);
    });

    test('reset ล้างทุกอย่าง', () async {
      store = UploadStore(
        picker: picker,
        client: clientThat(
          (_) async => http.Response(jsonEncode({'url': '/a.jpg'}), 200),
        ),
      );

      await store.pick(PickSource.camera);
      await store.upload(path: '/upload');
      store.reset();

      expect(store.stage, UploadStage.idle);
      expect(store.image, isNull);
      expect(store.uploadedUrl, isNull);
      expect(store.progress, isNull);
    });
  });
}
