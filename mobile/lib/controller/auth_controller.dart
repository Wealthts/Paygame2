import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/auth_service.dart';

class AuthController extends ChangeNotifier {
  final AuthService authService;

  AuthController(this.authService);

  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  // ========================================
  // Getters
  // ========================================

  bool get isLoading => _isLoading;

  UserModel? get currentUser => _currentUser;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _currentUser != null;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  // ========================================
  // Register
  // ========================================

  Future<bool> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
    required bool acceptedTerms,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.register(
        username: username,
        password: password,
        email: email,
        displayName: displayName,
        acceptedTerms: acceptedTerms,
      );

      return true;
    } catch (error) {
      if (error is ApiException) {
        _errorMessage = error.message;
      } else {
        _errorMessage = 'สมัครสมาชิกไม่สำเร็จ กรุณาลองอีกครั้ง';
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Forgot Password
  // ========================================

  Future<bool> requestPasswordReset({required String email}) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.requestPasswordReset(email: email);
      return true;
    } catch (error) {
      _errorMessage = error is ApiException
          ? error.message
          : 'ส่งรหัส OTP ไม่สำเร็จ กรุณาลองอีกครั้ง';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      _errorMessage = error is ApiException
          ? error.message
          : 'เปลี่ยนรหัสผ่านไม่สำเร็จ กรุณาลองอีกครั้ง';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Login
  // ========================================

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await authService.login(
        username: username,
        password: password,
      );

      _currentUser = user;

      return true;
    } catch (error) {
      if (error is ApiException) {
        _errorMessage = error.message;
      } else {
        _errorMessage = 'Unable to login. Please try again.';
      }

      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Restore Session
  // ========================================

  Future<void> restoreSession() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await authService.restoreSession();
    } catch (error) {
      if (error is ApiException) {
        _errorMessage = error.message;
      } else {
        _errorMessage = 'Unable to connect to server.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========================================
  // Logout
  // ========================================

  Future<void> logout() async {
    try {
      await authService.logout();
    } finally {
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ========================================
  // Clear Error
  // ========================================

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
