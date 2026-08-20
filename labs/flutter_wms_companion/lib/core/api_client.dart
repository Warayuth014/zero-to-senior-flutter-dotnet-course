import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_failure.dart';
import 'json_api.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.outcomeUnknown = false,
    this.kind = ApiFailureKind.contract,
    this.problem,
  });

  final String message;
  final int? statusCode;
  final bool outcomeUnknown;

  /// ชนิดของความล้มเหลว ใช้ตัดสินว่าลองใหม่ได้ไหมและควรบอกผู้ใช้ว่าอย่างไร
  final ApiFailureKind kind;

  /// รายละเอียดที่เซิร์ฟเวอร์ส่งมา ถ้ามี
  final ProblemDetails? problem;

  /// ข้อความที่เอาไปแสดงให้ผู้ใช้ได้
  ///
  /// ให้ความสำคัญกับสิ่งที่เซิร์ฟเวอร์บอกก่อน เพราะมันรู้เรื่องธุรกิจ
  /// มากกว่าข้อความกลางที่เราเขียนไว้
  String get userMessage => problem?.userMessage ?? message;

  @override
  String toString() => message;
}

class ApiClient implements JsonApi {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? authToken;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$path'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException {
      // GET ไม่เปลี่ยนข้อมูล จึงรู้แน่ว่าไม่มีอะไรเกิดขึ้น
      throw const ApiException(
        'เชื่อมต่อ server ไม่ได้',
        kind: ApiFailureKind.network,
      );
    } on http.ClientException {
      throw const ApiException(
        'เชื่อมต่อ server ไม่ได้',
        kind: ApiFailureKind.network,
      );
    } on TimeoutException {
      throw const ApiException(
        'server ไม่ตอบภายในเวลาที่กำหนด',
        kind: ApiFailureKind.timeout,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: {..._headers(), ...headers},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException {
      // POST เปลี่ยนข้อมูลได้ จึงไม่รู้ว่า server ทำไปแล้วหรือยัง
      throw const ApiException(
        'การเชื่อมต่อขาดระหว่างส่งคำสั่ง',
        outcomeUnknown: true,
        kind: ApiFailureKind.network,
      );
    } on http.ClientException {
      throw const ApiException(
        'การเชื่อมต่อขาดระหว่างส่งคำสั่ง',
        outcomeUnknown: true,
        kind: ApiFailureKind.network,
      );
    } on TimeoutException {
      throw const ApiException(
        'server ไม่ตอบหลังส่งคำสั่ง',
        outcomeUnknown: true,
        kind: ApiFailureKind.timeout,
      );
    }
  }

  Map<String, String> _headers() => {
    'Content-Type': 'application/json',
    if (authToken != null) 'Authorization': 'Bearer $authToken',
  };

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic>? json;
    try {
      if (response.body.isNotEmpty) {
        json = jsonDecode(response.body) as Map<String, dynamic>;
      }
    } on FormatException {
      json = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // 204 และ 200 ที่ body ว่าง ถือว่าสำเร็จ ไม่ต้องมี JSON
      return json ?? <String, dynamic>{};
    }

    final problem = ProblemDetails.tryParse(json);
    throw ApiException(
      // ข้อความสำรองเมื่อ server ไม่ได้บอกอะไรที่อ่านรู้เรื่อง
      problem?.userMessage ??
          json?['message']?.toString() ??
          'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
      kind: failureKindForStatus(response.statusCode),
      problem: problem,
    );
  }

  void close() => _client.close();
}
