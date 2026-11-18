import 'dart:convert';

import 'package:mobile/core/api_constant.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Small wrapper around flutter_secure_storage so session persistence has one
/// implementation and can be replaced/mocked in tests if required.
class SecureStorage {
  final FlutterSecureStorage _storage;

  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) {
    return _storage.delete(key: key);
  }

  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await write(ApiConstant.authTokenKey, token);
    await write(ApiConstant.authUserKey, jsonEncode(user));
  }

  Future<String?> readToken() => read(ApiConstant.authTokenKey);

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await read(ApiConstant.authUserKey);
    if (raw == null || raw.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      // Ignore corrupt local session data. The next login will replace it.
    }
    return null;
  }

  Future<void> clearSession() async {
    await delete(ApiConstant.authTokenKey);
    await delete(ApiConstant.authUserKey);
  }
}
