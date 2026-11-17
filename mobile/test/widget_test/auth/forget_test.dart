import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/view/auth/forget_view.dart';

void main() {
  testWidgets('forget-password screen explains unavailable API', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ForgetView()));
    expect(find.text('ลืมรหัสผ่าน'), findsOneWidget);
    expect(find.text('ยังไม่เปิดให้รีเซ็ตรหัสผ่านผ่านระบบ'), findsOneWidget);
  });
}