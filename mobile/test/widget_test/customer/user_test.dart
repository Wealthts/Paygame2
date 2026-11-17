import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/customer/customer_profile_service.dart';
import 'package:mobile/view/customer/user_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('profile page displays the signed-in user profile', (tester) async {
    await tester.pumpWidget(
      Provider<CustomerProfileService>(
        create: (_) => FakeCustomerProfileService(),
        child: const MaterialApp(home: CustomerProfileView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Test Player'), findsNWidgets(2));
    expect(find.text('@test_player'), findsOneWidget);
  });
}