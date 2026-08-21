import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/api_failure.dart';
import 'image_validation.dart';
import 'picked_image.dart';

/// ผลของการอัปโหลดหนึ่งครั้ง
///
/// เป็น sealed เพราะสามกรณีนี้พาผู้ใช้ไปคนละทาง และคอมไพเลอร์ควรบังคับ
/// ให้จัดการครบ (8.2)
sealed class UploadOutcome {
  const UploadOutcome();
}

/// สำเร็จ พร้อมที่อยู่ของไฟล์ที่เซิร์ฟเวอร์เก็บให้
class UploadSucceeded extends UploadOutcome {
  const UploadSucceeded(this.url);

  /// เส้นทางที่เซิร์ฟเวอร์คืนมา อาจเป็นเส้นทางสัมพัทธ์ เช่น `/uploads/a.jpg`
  ///
  /// เก็บตามที่ได้รับ ไม่ต่อ base URL ให้ตรงนี้ — เพราะ base URL เปลี่ยนได้
  /// เมื่อผู้ใช้สลับเซิร์ฟเวอร์ (10.6) ถ้าเก็บ URL เต็มไว้ วันที่สลับแล้ว
  /// รูปจะชี้ไปเครื่องเก่า
  final String url;
}

/// เซิร์ฟเวอร์ปฏิเสธด้วยเหตุผลที่ผู้ใช้แก้ได้
class UploadRejected extends UploadOutcome {
  const UploadRejected(this.message);
  final String message;
}

/// ล้มเหลวด้วยเหตุอื่น
class UploadFailed extends UploadOutcome {
  const UploadFailed(this.kind, this.message, {this.outcomeUnknown = false});

  final ApiFailureKind kind;
  final String message;

  /// ไม่รู้ว่าเซิร์ฟเวอร์รับไฟล์ไปแล้วหรือยัง
  ///
  /// การอัปโหลดที่ขาดกลางทางเป็นกรณีที่ไม่รู้ผทเสมอ (7.10) — ส่งซ้ำแล้ว
  /// อาจได้รูปสองใบ ซึ่งเป็นเหตุผลที่ต้องมี Idempotency-Key
  final bool outcomeUnknown;
}

/// ผู้ใช้กดยกเลิกระหว่างอัปโหลด
class UploadCancelled extends UploadOutcome {
  const UploadCancelled();
}

/// ส่งไฟล์ไปเซิร์ฟเวอร์ด้วย multipart
class UploadClient {
  UploadClient({required this.baseUrl, http.Client? client, this.timeout = const Duration(seconds: 60)})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// นานกว่าคำขอปกติมาก เพราะไฟล์ไม่กี่เมกะบนเน็ตคลังใช้เวลาเป็นสิบวินาที
  final Duration timeout;

  String? authToken;

  /// อัปโหลดรูปหนึ่งใบ
  ///
  /// [onProgress] ถูกเรียกระหว่างส่ง โดยบอกจำนวนไบต์ที่ส่งไปแล้วกับทั้งหมด
  /// [cancel] ถ้าเสร็จก่อนการอัปโหลดจบ จะหยุดส่งและคืน [UploadCancelled]
  Future<UploadOutcome> uploadImage({
    required String path,
    required PickedImage image,
    required String commandId,
    Map<String, String> fields = const {},
    void Function(int sent, int total)? onProgress,
    Future<void>? cancel,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        // ห้ามตั้ง Content-Type เอง — MultipartRequest ต้องใส่ boundary
        // ที่มันสุ่มมาเอง ถ้าเราทับ เซิร์ฟเวอร์จะแยกส่วนของไฟล์ไม่ออก (13.3)
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        // ส่งซ้ำเพราะเน็ตหลุด ต้องไม่ได้รูปสองใบ (7.13)
        'Idempotency-Key': commandId,
      })
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          // ชื่อช่องต้องตรงกับที่ฝั่ง .NET ตั้งไว้เป๊ะ ๆ ไม่งั้นจะได้
          // 400 ที่บอกแค่ว่า "file is required" โดยที่เราส่งไฟล์ไปแล้ว
          'file',
          image.bytes,
          filename: safeFileName(image.fileName, extension: image.extension),
        ),
      );

    try {
      final streamed = await _send(request, onProgress: onProgress, cancel: cancel)
          .timeout(timeout);
      if (streamed == null) return const UploadCancelled();

      final response = await http.Response.fromStream(streamed);
      return _readResponse(response);
    } on SocketException {
      return const UploadFailed(
        ApiFailureKind.network,
        'การเชื่อมต่อขาดระหว่างอัปโหลด',
        outcomeUnknown: true,
      );
    } on http.ClientException {
      return const UploadFailed(
        ApiFailureKind.network,
        'การเชื่อมต่อขาดระหว่างอัปโหลด',
        outcomeUnknown: true,
      );
    } on TimeoutException {
      return const UploadFailed(
        ApiFailureKind.timeout,
        'อัปโหลดไม่เสร็จภายในเวลาที่กำหนด',
        outcomeUnknown: true,
      );
    }
  }

  /// ส่งคำขอพร้อมรายงานความคืบหน้า
  ///
  /// `MultipartRequest` ไม่มีการรายงานความคืบหน้าให้ จึงต้องห่อ stream ของ
  /// ตัวมันเองแล้วนับไบต์ที่ไหลผ่าน (13.8)
  Future<http.StreamedResponse?> _send(
    http.MultipartRequest request, {
    void Function(int sent, int total)? onProgress,
    Future<void>? cancel,
  }) async {
    final total = request.contentLength;
    var sent = 0;
    var cancelled = false;
    unawaited(cancel?.then((_) => cancelled = true));

    final counted = request.finalize().transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          if (cancelled) {
            sink.close();
            return;
          }
          sent += chunk.length;
          onProgress?.call(sent, total);
          sink.add(chunk);
        },
      ),
    );

    final outgoing = http.StreamedRequest(request.method, request.url)
      ..headers.addAll(request.headers)
      ..contentLength = total;

    unawaited(
      counted.forEach(outgoing.sink.add).whenComplete(outgoing.sink.close),
    );

    final response = await _client.send(outgoing);
    return cancelled ? null : response;
  }

  UploadOutcome _readResponse(http.Response response) {
    final code = response.statusCode;

    if (code >= 200 && code < 300) {
      final url = _readUrl(response.body);
      if (url == null) {
        // ตอบ 200 แต่ไม่บอกที่อยู่ไฟล์ — เราเก็บอะไรไว้แสดงไม่ได้เลย
        return const UploadFailed(
          ApiFailureKind.contract,
          'เซิร์ฟเวอร์รับไฟล์แล้วแต่ไม่ได้บอกที่อยู่',
        );
      }
      return UploadSucceeded(url);
    }

    final problem = ProblemDetails.tryParse(_tryDecode(response.body));
    final message = problem?.userMessage ?? 'อัปโหลดไม่สำเร็จ (HTTP $code)';
    final kind = failureKindForStatus(code);

    // 413 คือไฟล์ใหญ่เกินที่เซิร์ฟเวอร์รับ ซึ่งผู้ใช้แก้ได้เอง
    if (code == 413) {
      return const UploadRejected(
        'ไฟล์ใหญ่เกินที่เซิร์ฟเวอร์รับได้ ลองถ่ายใหม่ที่ความละเอียดต่ำลง',
      );
    }
    if (kind == ApiFailureKind.validation) return UploadRejected(message);

    return UploadFailed(kind, message);
  }

  String? _readUrl(String body) {
    final json = _tryDecode(body);
    if (json == null) return null;
    for (final key in ['url', 'imageUrl', 'path', 'location']) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Map<String, dynamic>? _tryDecode(String body) {
    if (body.isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  void close() => _client.close();
}
