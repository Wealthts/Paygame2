import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/view/auth/index_view.dart';

void main() {
  testWidgets('welcome screen exposes login and registration actions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: IndexView()));
    expect(find.text('PAYGAME'), findsOneWidget);
    expect(find.text('เข้าสู่ระบบ'), findsOneWidget);
    expect(find.text('สมัครสมาชิก'), findsOneWidget);
  });
}