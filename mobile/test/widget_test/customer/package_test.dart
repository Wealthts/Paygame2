import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/customer/customer_package_service.dart';
import 'package:mobile/view/customer/package_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('customer package page displays packages for selected game', (tester) async {
    await tester.pumpWidget(
      Provider<CustomerPackageService>(
        create: (_) => FakeCustomerPackageService(),
        child: MaterialApp(home: CustomerPackageView(game: testGame)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Arena Test'), findsWidgets);
    expect(find.text('เลือกแพ็กเกจที่ต้องการ'), findsOneWidget);
    expect(find.text('พบ 1 แพ็กเกจ'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });
}
