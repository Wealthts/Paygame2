import 'package:material_ui/material_ui.dart';

import 'package:mobile/core/app_colors.dart';
import 'package:mobile/view/auth/login_view.dart';
import 'package:mobile/view/auth/register_view.dart';

class IndexView extends StatelessWidget {
  const IndexView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.peach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_esports_rounded,
                      size: 48,
                      color: AppColors.red,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'PAYGAME',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.red,
                      fontWeight: FontWeight.w800,
                      fontSize: 34,
                      letterSpacing: 2.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เติมเกมและจัดการรายการของคุณในที่เดียว',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 34),
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginView(),
                      ),
                    ),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterView(),
                      ),
                    ),
                    child: const Text('สมัครสมาชิก'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
