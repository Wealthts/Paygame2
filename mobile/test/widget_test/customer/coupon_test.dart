import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/coupon_view.dart';

void main() {
  // This uses one usable coupon and one disabled coupon to check the filter.
  testWidgets('6. Customer sees coupons and filters usable coupons', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<UserCouponService>.value(
        value: _CustomerCoupons(
          coupons: [
            _customerCoupon('READY', true),
            _customerCoupon('DISABLED', false),
          ],
        ),
        child: const MaterialApp(home: CustomerCouponView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('READY'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('DISABLED'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 500));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'พร้อมใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('DISABLED'), findsNothing);
  });

  // Claiming a code is checked using a fake service, so no backend is involved.
  testWidgets('7. Customer validates and claims a coupon code', (tester) async {
    final service = _CustomerCoupons();
    await tester.pumpWidget(
      Provider<UserCouponService>.value(
        value: service,
        child: const MaterialApp(home: CustomerCouponView()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มคูปอง'));
    await tester.pump();
    expect(find.text('กรุณากรอกรหัสคูปอง'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'HELLO');
    await tester.tap(find.text('เพิ่มคูปอง'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.claimedCode, 'HELLO');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
  });
}

CustomerCouponModel _customerCoupon(String code, bool active) =>
    CustomerCouponModel(
      userCouponId: code == 'READY' ? 1 : 2,
      couponId: 3,
      code: code,
      discountType: 'percent',
      discountValue: 10,
      minOrderAmount: 100,
      maxDiscountAmount: 50,
      startDate: '2020-01-01T00:00:00.000Z',
      endDate: '2099-12-31T23:59:59.000Z',
      usedAt: null,
      couponIsActive: active,
    );

class _CustomerCoupons extends UserCouponService {
  _CustomerCoupons({this.coupons = const []}) : super(ApiService());
  final List<CustomerCouponModel> coupons;
  String? claimedCode;
  @override
  Future<List<CustomerCouponModel>> getMyCoupons() async => coupons;
  @override
  Future<void> claimCouponByCode(String code) async {
    claimedCode = code;
  }
}
