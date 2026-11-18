import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/admin/user_coupon_view.dart';

void main() {
  // The screen uses these fake services so the test does not need a running server.
  testWidgets('5. Admin assigns a coupon to a member', (tester) async {
    final assignments = _Assignments();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserCouponService>.value(value: assignments),
          Provider<CouponService>.value(value: _Coupons()),
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

class _Assignments extends UserCouponService {
  _Assignments() : super(ApiService());

  int? assignedUserId;
  int? assignedCouponId;

  @override
  Future<List<UserCouponModel>> getAllUserCoupons() async => [
    _assignment(10, 'WELCOME'),
  ];

  @override
  Future<List<UserOptionModel>> getAvailableUsers() async => [
    const UserOptionModel(
      userId: 8,
      username: 'sam',
      displayName: 'Sam',
      email: 'sam@example.com',
    ),
  ];

  @override
  Future<void> assignCoupon({
    required int userId,
    required int couponId,
  }) async {
    assignedUserId = userId;
    assignedCouponId = couponId;
  }
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

// The assignment dialog needs at least one active coupon to offer to the admin.
class _Coupons extends CouponService {
  _Coupons() : super(ApiService());
  @override
  Future<List<CouponModel>> getAllCoupons() async => [
    CouponModel(
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
    ),
  ];
}
