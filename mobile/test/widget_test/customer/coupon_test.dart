import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/coupon_view.dart';

import '../../support/fake_services.dart';


void main() {
  testWidgets('coupon page renders the empty-coupon state', (tester) async {
    await tester.pumpWidget(
      Provider<UserCouponService>(
        create: (_) => FakeUserCouponService(),
        child: const MaterialApp(home: CustomerCouponView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('คูปองของฉัน'), findsOneWidget);
  });
}