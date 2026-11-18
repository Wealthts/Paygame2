import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/validator.dart';

/// Forgot password flow:
///   Step 1 - enter email, server sends a 6-digit OTP to that email
///   Step 2 - enter OTP + new password, then return `true` to the caller
class ForgetView extends StatefulWidget {
  const ForgetView({super.key});

  @override
  State<ForgetView> createState() => _ForgetViewState();
}

class _ForgetViewState extends State<ForgetView> {
  static const int _resendSeconds = 60;

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Clear any error left over from the login/register screens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthController>().clearError();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _sendOtp() async {
    if (!(_emailFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await context.read<AuthController>().requestPasswordReset(
      email: _emailController.text.trim(),
    );

    if (!mounted || !success) return;

    setState(() => _otpSent = true);
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งรหัส OTP ไปที่อีเมลแล้ว กรุณาตรวจสอบกล่องจดหมาย')),
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft > 0) return;
    final success = await context.read<AuthController>().requestPasswordReset(
      email: _emailController.text.trim(),
    );
    if (!mounted || !success) return;
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งรหัส OTP ใหม่แล้ว')),
    );
  }

  Future<void> _resetPassword() async {
    if (!(_resetFormKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final success = await context.read<AuthController>().resetPassword(
      email: _emailController.text.trim(),
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (mounted && success) Navigator.of(context).pop(true);
  }

  void _backToEmail() {
    _timer?.cancel();
    context.read<AuthController>().clearError();
    setState(() {
      _otpSent = false;
      _secondsLeft = 0;
      _otpController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _errorBox(AuthController auth) {
    if (auth.errorMessage == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.dangerBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          auth.errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.danger),
        ),
      ),
    );
  }

  Widget _loadingOr(AuthController auth, String text) {
    if (!auth.isLoading) return Text(text);
    return const SizedBox(
      width: 21,
      height: 21,
      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white),
    );
  }

  Widget _buildEmailStep(AuthController auth) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'กรอก Email ที่ใช้สมัครสมาชิก เราจะส่งรหัส OTP 6 หลักไปให้',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _label('Email'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendOtp(),
            decoration: const InputDecoration(
              hintText: 'name@example.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: AppValidator.email,
          ),
          _errorBox(auth),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: auth.isLoading ? null : _sendOtp,
              child: _loadingOr(auth, 'ส่งรหัส OTP'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep(AuthController auth) {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'เราส่งรหัส OTP ไปที่ ${_emailController.text.trim()}\n'
            'รหัสมีอายุ 10 นาที',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          _label('รหัส OTP'),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: 'ตัวเลข 6 หลัก',
              prefixIcon: Icon(Icons.pin_outlined),
              counterText: '',
            ),
            validator: (value) {
              final text = value?.trim() ?? '';
              if (text.isEmpty) return 'กรุณากรอกรหัส OTP';
              if (text.length != 6) return 'รหัส OTP ต้องมี 6 หลัก';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _label('รหัสผ่านใหม่'),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              hintText: 'อย่างน้อย 8 ตัวอักษร',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'แสดงรหัสผ่าน' : 'ซ่อนรหัสผ่าน',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: AppValidator.password,
          ),
          const SizedBox(height: 16),
          _label('ยืนยันรหัสผ่านใหม่'),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: InputDecoration(
              hintText: 'กรอกรหัสผ่านอีกครั้ง',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                tooltip: _obscureConfirmPassword
                    ? 'แสดงรหัสผ่าน'
                    : 'ซ่อนรหัสผ่าน',
                onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => AppValidator.confirmPassword(
              value,
              passwordValue: _passwordController.text,
            ),
          ),
          _errorBox(auth),
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: FilledButton(
              onPressed: auth.isLoading ? null : _resetPassword,
              child: _loadingOr(auth, 'เปลี่ยนรหัสผ่าน'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: (auth.isLoading || _secondsLeft > 0) ? null : _resendOtp,
            child: Text(
              _secondsLeft > 0
                  ? 'ส่งรหัสอีกครั้งได้ใน $_secondsLeft วินาที'
                  : 'ส่งรหัส OTP อีกครั้ง',
            ),
          ),
          TextButton(
            onPressed: auth.isLoading ? null : _backToEmail,
            child: const Text('เปลี่ยน Email'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_outlined,
                      color: AppColors.goldText,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _otpSent ? 'ตั้งรหัสผ่านใหม่' : 'รีเซ็ตรหัสผ่าน',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _otpSent ? _buildResetStep(auth) : _buildEmailStep(auth),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
