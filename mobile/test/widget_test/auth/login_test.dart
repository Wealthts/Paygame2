import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/view/auth/login_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('login form validates empty username and password', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 0.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(withAuthController(const LoginView()));
    await tester.tap(find.text('เข้าสู่ระบบ'));
    await tester.pump();

    expect(find.text('กรุณากรอก Username'), findsOneWidget);
    expect(find.text('กรุณากรอกรหัสผ่าน'), findsOneWidget);
  });
}