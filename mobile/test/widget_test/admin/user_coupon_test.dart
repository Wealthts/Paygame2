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
  testWidgets('3. Admin sees member coupon assignments and can search', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserCouponService>.value(value: _Assignments()),
          Provider<CouponService>.value(value: _Coupons()),
        ],
        child: const MaterialApp(home: UserCouponView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('คูปองของสมาชิก'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'missing');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'missing',
    );
  });

  testWidgets('4. Admin can open the assign coupon dialog', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<UserCouponService>.value(value: _Assignments()),
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
  });
}

class _Assignments extends UserCouponService {
  _Assignments() : super(ApiService());
  @override
  Future<List<UserCouponModel>> getAllUserCoupons() async => [
    UserCouponModel(
      userCouponId: 10,
      userId: 8,
      couponId: 2,
      username: 'sam',
      displayName: 'Sam',
      email: 'sam@example.com',
      code: 'WELCOME',
      discountType: 'percent',
      discountValue: 5,
      minOrderAmount: 100,
      maxDiscountAmount: 50,
      startDate: '2026-01-01',
      endDate: '2099-12-31',
      usedAt: null,
      couponIsActive: true,
    ),
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
}

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
