import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/service/customer/customer_game_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/homepage_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('customer homepage loads game cards and live points balance', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthController(FakeAuthService())),
          Provider<CustomerGameService>(create: (_) => FakeCustomerGameService()),
          Provider<PointService>(create: (_) => FakePointService()),
        ],
        child: const MaterialApp(home: HomePageView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PAYGAME'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('แต้มสะสม'), findsOneWidget);
  });
}