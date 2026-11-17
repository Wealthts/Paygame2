import 'package:material_ui/material_ui.dart';

import 'package:mobile/core/app_colors.dart';

/// Password reset is intentionally informational: the current Express API
/// does not expose a password-reset endpoint.
class ForgetView extends StatelessWidget {
  const ForgetView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('ลืมรหัสผ่าน')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_reset_outlined,
                      color: AppColors.goldText,
                      size: 56,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ยังไม่เปิดให้รีเซ็ตรหัสผ่านผ่านระบบ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'API ปัจจุบันยังไม่มี endpoint สำหรับรีเซ็ตรหัสผ่าน '
                      'กรุณาติดต่อผู้ดูแลระบบเพื่อขอความช่วยเหลือ',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('กลับ'),
                    ),
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
