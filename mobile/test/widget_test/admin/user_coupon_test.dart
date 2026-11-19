import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/admin/user_coupon_view.dart';

import '../../support/fake_services.dart';

void main() {
  // The screen uses these fake services so the test does not need a running server.
  testWidgets('5. Admin assigns a coupon to a member', (tester) async {
    final assignments = FakeUserCouponService(
      userCoupons: [_assignment(10, 'WELCOME')],
      availableUsers: [
        const UserOptionModel(
          userId: 8,
          username: 'sam',
          displayName: 'Sam',
          email: 'sam@example.com',
        ),
      ],
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserCouponService>.value(value: assignments),
          Provider<CouponService>.value(
            value: FakeCouponService(coupons: [_coupon()]),
          ),
        ],
        child: const MaterialApp(home: UserCouponView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('มอบคูปอง'));
    await tester.pumpAndSettle();
    expect(find.text('มอบคูปองให้สมาชิก'), findsOneWidget);
    expect(find.text('เลือกสมาชิก'), findsOneWidget);
    expect(find.text('เลือกคูปอง'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'มอบคูปอง'));
    await tester.pumpAndSettle();

    expect(assignments.assignedUserId, 8);
    expect(assignments.assignedCouponId, 2);
  });
}

UserCouponModel _assignment(int assignmentId, String code) => UserCouponModel(
  userCouponId: assignmentId,
  userId: 8,
  couponId: 2,
  username: 'sam',
  displayName: 'Sam',
  email: 'sam@example.com',
  code: code,
  discountType: 'percent',
  discountValue: 5,
  minOrderAmount: 100,
  maxDiscountAmount: 50,
  startDate: '2026-01-01',
  endDate: '2099-12-31',
  usedAt: null,
  couponIsActive: true,
);

// The dialog needs one active coupon to offer as an option.
CouponModel _coupon() => CouponModel(
  couponId: 2,
  code: 'SAVE',
  discountType: 'fixed',
  discountValue: 20,
  minOrderAmount: 0,
  maxDiscountAmount: null,
  useLimit: null,
  useCount: 0,
  startDate: '2026-01-01',
  endDate: '2099-12-31',
  isActive: true,
);
