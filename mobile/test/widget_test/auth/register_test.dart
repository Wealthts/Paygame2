import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/view/auth/register_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('register form displays required-field validation', (tester) async {
    await tester.pumpWidget(withAuthController(const RegisterView()));
    final submitButton = find.widgetWithText(FilledButton, 'สมัครสมาชิก');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('กรุณากรอกชื่อที่ใช้แสดง'), findsOneWidget);
    expect(find.text('กรุณากรอก Username'), findsOneWidget);
    expect(find.text('กรุณากรอก Email'), findsOneWidget);
  });
}