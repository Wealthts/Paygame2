import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/view/admin/coupon_view.dart';

void main() {
  // This fake service gives the admin screen two coupons to display and search.
  testWidgets('1. Admin coupon screen lists coupons and filters by search', (
    tester,
  ) async {
    final service = _Coupons()
      ..coupons = [_coupon(1, 'SAVE10', true), _coupon(2, 'OLD20', false)];
    await tester.pumpWidget(
      Provider<CouponService>.value(
        value: service,
        child: const MaterialApp(home: CouponView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('จัดการคูปอง'), findsOneWidget);
    expect(find.text('SAVE10'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('OLD20'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'SAVE10');
    await tester.pumpAndSettle();
    expect(find.text('OLD20'), findsNothing);
  });

  // Opening the form without a code should show the form's validation message.
  testWidgets('2. Admin can open create coupon form and see validation feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<CouponService>.value(
        value: _Coupons(),
        child: const MaterialApp(home: CouponView()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('เพิ่มคูปอง'));
    await tester.pumpAndSettle();
    expect(find.text('เพิ่มคูปอง'), findsNWidgets(2));
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();
    expect(find.text('กรุณากรอกรหัสคูปอง'), findsOneWidget);
  });
}

CouponModel _coupon(int id, String code, bool active) => CouponModel(
  couponId: id,
  code: code,
  discountType: 'fixed',
  discountValue: 10,
  minOrderAmount: 0,
  maxDiscountAmount: null,
  useLimit: null,
  useCount: 0,
  startDate: '2026-01-01',
  endDate: '2099-12-31',
  isActive: active,
);

class _Coupons extends CouponService {
  _Coupons() : super(ApiService());
  List<CouponModel> coupons = [];
  @override
  Future<List<CouponModel>> getAllCoupons() async => coupons;
}
