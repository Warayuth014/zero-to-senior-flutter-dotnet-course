import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// ผลของการทดสอบว่าที่อยู่นี้ตอบไหม
class ProbeResult {
  const ProbeResult({
    required this.ok,
    required this.message,
    this.statusCode,
    this.elapsedMs = 0,
  });

  /// จริงเฉพาะเมื่อที่อยู่นี้ตอบกลับมาในฐานะ WMS จริง ๆ
  final bool ok;

  /// ข้อความที่แสดงให้ผู้ใช้ได้เลย
  final String message;

  /// null เมื่อไม่มีอะไรตอบกลับมาเลย
  final int? statusCode;

  final int elapsedMs;
}

/// จริงเฉพาะกับ JSON ที่ `mobile_health` ตอบจริง ๆ
///
/// **รหัสตอบกลับอย่างเดียวพิสูจน์อะไรไม่ได้ที่นี่** — เซิร์ฟเวอร์ WMS เป็น
/// เว็บ Blazor ที่ตั้ง `MapFallbackToPage("/_Host")` ไว้ แปลว่าทุกเส้นทางที่
/// ไม่ตรงกับอะไรเลย รวมถึงเส้นทางที่เกิดจาก Base Path ผิด จะได้ 200 พร้อม
/// HTML ของหน้าเว็บกลับมา การอ่านเนื้อหาเป็นทางเดียวที่แยกออกว่า
/// "API ตอบ" ต่างจาก "หน้าเว็บตอบ" (10.10)
bool isHealthPayload(String body) {
  try {
    final json = jsonDecode(body);
    return json is Map && json['service'] == 'WMS' && json['ok'] == true;
  } catch (_) {
    return false; // HTML หรืออะไรก็ตามที่ไม่ใช่คำตอบของเรา
  }
}

/// ถามเซิร์ฟเวอร์ที่ผู้ใช้กำลังกรอกว่ายังมีชีวิตอยู่ไหม
///
/// ใช้ [http.Client] ตรง ๆ ไม่ผ่าน ApiClient โดยตั้งใจ — ApiClient ยิงไปที่
/// profile ที่ใช้งานอยู่เสมอ แต่ปุ่ม "ทดสอบการเชื่อมต่อ" ต้องลองที่อยู่ที่
/// พิมพ์อยู่ในฟอร์ม โดยไม่ไปรบกวนที่อยู่ที่ทั้งแอปกำลังใช้ (10.9)
///
/// เส้นทาง health เปิดให้เรียกโดยไม่ต้องเข้าสู่ระบบ จึงทดสอบก่อนล็อกอินได้
Future<ProbeResult> probeServer({
  required String baseUrl,
  Duration timeout = const Duration(seconds: 8),
  http.Client? client,
}) async {
  final watch = Stopwatch()..start();
  final owned = client == null;
  final httpClient = client ?? http.Client();

  Uri uri;
  try {
    uri = Uri.parse('$baseUrl/api/WMS/mobile_health');
    if (!uri.hasScheme || uri.host.isEmpty) throw const FormatException();
  } on FormatException {
    if (owned) httpClient.close();
    return const ProbeResult(ok: false, message: 'ที่อยู่เซิร์ฟเวอร์ไม่ถูกต้อง');
  }

  try {
    final response = await httpClient.get(uri).timeout(timeout);
    watch.stop();
    final code = response.statusCode;
    final answered = code >= 200 && code < 300;
    final isWms = answered && isHealthPayload(response.body);

    return ProbeResult(
      ok: isWms,
      statusCode: code,
      elapsedMs: watch.elapsedMilliseconds,
      message: isWms
          ? 'เชื่อมต่อสำเร็จ · ${watch.elapsedMilliseconds} ms'
          : answered
          ? 'เซิร์ฟเวอร์ตอบกลับ แต่ไม่ใช่ WMS API — ตรวจ Base Path'
          : 'ตอบกลับ HTTP $code — ไม่ใช่เซิร์ฟเวอร์ WMS',
    );
  } on TimeoutException {
    watch.stop();
    return ProbeResult(
      ok: false,
      elapsedMs: watch.elapsedMilliseconds,
      message: 'ไม่ตอบใน ${timeout.inSeconds} วินาที — ตรวจ IP และพอร์ต',
    );
  } on HandshakeException {
    watch.stop();
    return ProbeResult(
      ok: false,
      elapsedMs: watch.elapsedMilliseconds,
      message: 'ใบรับรอง HTTPS ไม่ผ่าน — ลองใช้ HTTP หรือแก้ใบรับรอง',
    );
  } on SocketException {
    watch.stop();
    return ProbeResult(
      ok: false,
      elapsedMs: watch.elapsedMilliseconds,
      message: 'ติดต่อที่อยู่นี้ไม่ได้ — ตรวจสัญญาณและเครื่องเซิร์ฟเวอร์',
    );
  } on http.ClientException catch (error) {
    watch.stop();
    return ProbeResult(
      ok: false,
      elapsedMs: watch.elapsedMilliseconds,
      message: 'เชื่อมต่อไม่สำเร็จ: ${error.message}',
    );
  } finally {
    if (owned) httpClient.close();
  }
}
