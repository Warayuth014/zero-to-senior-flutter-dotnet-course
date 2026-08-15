import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'json_api.dart';

class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.outcomeUnknown = false,
  });

  final String message;
  final int? statusCode;
  final bool outcomeUnknown;

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
      throw const ApiException('เชื่อมต่อ server ไม่ได้');
    } on http.ClientException {
      throw const ApiException('เชื่อมต่อ server ไม่ได้');
    } on TimeoutException {
      throw const ApiException('server ไม่ตอบภายในเวลาที่กำหนด');
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
      throw const ApiException(
        'การเชื่อมต่อขาดระหว่างส่งคำสั่ง',
        outcomeUnknown: true,
      );
    } on http.ClientException {
      throw const ApiException(
        'การเชื่อมต่อขาดระหว่างส่งคำสั่ง',
        outcomeUnknown: true,
      );
    } on TimeoutException {
      throw const ApiException(
        'server ไม่ตอบหลังส่งคำสั่ง',
        outcomeUnknown: true,
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
      return json ?? <String, dynamic>{};
    }
    throw ApiException(
      json?['message']?.toString() ?? 'HTTP ${response.statusCode}',
      statusCode: response.statusCode,
    );
  }

  void close() => _client.close();
}
