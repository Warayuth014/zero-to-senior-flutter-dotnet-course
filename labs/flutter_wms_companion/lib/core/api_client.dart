import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? authToken;

  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl$path'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException {
      throw const ApiException('เชื่อมต่อ server ไม่ได้');
    } on TimeoutException {
      throw const ApiException('server ไม่ตอบภายในเวลาที่กำหนด');
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      return _decode(response);
    } on SocketException {
      throw const ApiException('เชื่อมต่อ server ไม่ได้');
    } on TimeoutException {
      throw const ApiException('server ไม่ตอบภายในเวลาที่กำหนด');
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
}
