import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/order_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('order page renders player information and order summary', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OrderService>(create: (_) => FakeOrderService()),
          Provider<PointService>(create: (_) => FakePointService()),
          Provider<UserCouponService>(create: (_) => FakeUserCouponService()),
        ],
        child: MaterialApp(
          home: CustomerOrderView(game: testGame, package: testPackage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลผู้เล่น'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
  });
}