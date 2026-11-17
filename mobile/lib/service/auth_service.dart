import 'package:mobile/core/api_constant.dart';
import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';

class AuthService {
  final ApiService api;

  AuthService(this.api);

  // ========================================
  // Register
  // ========================================

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
  }) async {
    final cleanUsername = username.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanDisplayName = displayName.trim();

    if (cleanUsername.isEmpty ||
        password.isEmpty ||
        cleanEmail.isEmpty ||
        cleanDisplayName.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'กรุณากรอกข้อมูลให้ครบทุกช่อง',
      );
    }

    if (cleanUsername.length > 100 ||
        cleanEmail.length > 100 ||
        cleanDisplayName.length > 100 ||
        password.length < 8 ||
        password.length > 128) {
      throw const ApiException(
        statusCode: 400,
        message: 'ข้อมูลไม่ถูกต้อง หรือรหัสผ่านมีความยาวไม่เหมาะสม',
      );
    }

    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailPattern.hasMatch(cleanEmail)) {
      throw const ApiException(
        statusCode: 400,
        message: 'รูปแบบ Email ไม่ถูกต้อง',
      );
    }

    final response = await api.post(
      ApiConstant.authRegister,
      requiresAuth: false,
      body: {
        'username': cleanUsername,
        'password': password,
        'email': cleanEmail,
        'display_name': cleanDisplayName,
      },
    );

    if (response is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'รูปแบบข้อมูลตอบกลับจากเซิร์ฟเวอร์ไม่ถูกต้อง',
      );
    }

    final data = Map<String, dynamic>.from(response);

    if (data['user_id'] == null) {
      throw const ApiException(
        statusCode: 500,
        message: 'ไม่พบข้อมูลบัญชีที่สมัคร',
      );
    }
  }

  // ========================================
  // Login
  // ========================================
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    if (username.trim().isEmpty || password.isEmpty) {
      throw const ApiException(
        statusCode: 400,
        message: 'Please enter username and password',
      );
    }

    final response = await api.post(
      ApiConstant.authLogin,
      requiresAuth: false,
      body: {'username': username.trim(), 'password': password},
    );

    if (response is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid login response',
      );
    }

    final data = Map<String, dynamic>.from(response);

    final token = data['token'];
    final userData = data['user'];

    if (token is! String || token.trim().isEmpty) {
      throw const ApiException(
        statusCode: 500,
        message: 'Authentication token not found',
      );
    }

    if (userData is! Map) {
      throw const ApiException(
        statusCode: 500,
        message: 'Invalid user information',
      );
    }

    final user = UserModel.fromJson(Map<String, dynamic>.from(userData));

    await api.saveSession(token: token, user: user.toJson());

    return user;
  }

  // ========================================
  // Restore Session
  // ========================================
  Future<UserModel?> restoreSession() async {
    final token = await api.getToken();
    final savedUser = await api.getSavedUser();

    if (token == null || token.trim().isEmpty || savedUser == null) {
      return null;
    }

    try {
      await api.get('/api/points/my-points');

      return UserModel.fromJson(savedUser);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await api.clearSession();
        return null;
      }

      rethrow;
    }
  }

  // ========================================
  // Logout
  // ========================================
  Future<void> logout() async {
    await api.clearSession();
  }
}
