import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/view/auth/forget_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('forget-password screen asks for email first', (tester) async {
    await tester.pumpWidget(withAuthController(const ForgetView()));
    expect(find.text('ลืมรหัสผ่าน'), findsOneWidget);
    expect(find.text('ส่งรหัส OTP'), findsOneWidget);
  });

  testWidgets('forget-password validates email before sending OTP', (
    tester,
  ) async {
    await tester.pumpWidget(withAuthController(const ForgetView()));
    await tester.tap(find.widgetWithText(FilledButton, 'ส่งรหัส OTP'));
    await tester.pump();
    expect(find.text('กรุณากรอก Email'), findsOneWidget);
  });

  testWidgets('forget-password moves to OTP step after email is sent', (
    tester,
  ) async {
    await tester.pumpWidget(withAuthController(const ForgetView()));
    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'ส่งรหัส OTP'));
    await tester.pump();
    await tester.pump();
    expect(find.text('ตั้งรหัสผ่านใหม่'), findsOneWidget);
    expect(find.text('เปลี่ยนรหัสผ่าน'), findsOneWidget);
    // stop the resend countdown timer
    await tester.pumpWidget(const SizedBox());
  });
}
