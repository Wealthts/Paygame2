import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mobile/core/api_constant.dart';
import 'package:mobile/core/secure_storage.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

/// HTTP client for the PayGame REST API.
/// The default host is localhost because the current development target is
/// Flutter Web running in Chrome with the Node server on port 3000.
class ApiService {
  final http.Client client;
  final SecureStorage storage;

  ApiService({
    http.Client? client,
    FlutterSecureStorage? storage,
    SecureStorage? secureStorage,
  }) : client = client ?? http.Client(),
       storage = secureStorage ?? SecureStorage(storage: storage);

  Uri buildUri(String path) {
    final base = ApiConstant.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final endpoint = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$endpoint');
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) {
    return storage.saveSession(token: token, user: user);
  }

  Future<String?> getToken() => storage.readToken();
  Future<Map<String, dynamic>?> getSavedUser() => storage.readUser();
  Future<void> clearSession() => storage.clearSession();

  Future<dynamic> get(String path, {bool requiresAuth = true}) {
    return send('GET', path, requiresAuth: requiresAuth);
  }

  Future<dynamic> post(String path, {Object? body, bool requiresAuth = true}) {
    return send('POST', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> put(String path, {Object? body, bool requiresAuth = true}) {
    return send('PUT', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> patch(String path, {Object? body, bool requiresAuth = true}) {
    return send('PATCH', path, body: body, requiresAuth: requiresAuth);
  }

  Future<dynamic> delete(String path, {bool requiresAuth = true}) {
    return send('DELETE', path, requiresAuth: requiresAuth);
  }

  Future<dynamic> send(
    String method,
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};

    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }

    if (requiresAuth) {
      final token = await getToken();
      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          statusCode: 401,
          message: 'กรุณาเข้าสู่ระบบก่อนใช้งาน',
        );
      }
      headers['Authorization'] = 'Bearer $token';
    }

    final request = http.Request(method, buildUri(path))
      ..headers.addAll(headers);

    if (body != null) request.body = jsonEncode(body);

    try {
      final streamedResponse = await client
          .send(request)
          .timeout(ApiConstant.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(ApiConstant.requestTimeout);
          
      final responseData = _decodeResponse(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401 && requiresAuth) {
          await clearSession();
        }

        final message = responseData is Map && responseData['message'] is String
            ? responseData['message'] as String
            : 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์ (${response.statusCode})';
        throw ApiException(statusCode: response.statusCode, message: message);
      }

      return responseData;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        message: 'เชื่อมต่อเซิร์ฟเวอร์หมดเวลา กรุณาลองใหม่',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        message: 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบ Node server',
      );
    }
  }

  dynamic _decodeResponse(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(body);
    } on FormatException {
      return body;
    }
  }

  void dispose() => client.close();
}
