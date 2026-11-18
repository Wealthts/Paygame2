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
    final service = _Coupons();
    service.coupons = [
      _coupon(1, 'SAVE10', true),
      _coupon(2, 'OLD20', false, discountType: 'percent'),
    ];
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
  testWidgets('2. Admin validates and creates a coupon', (tester) async {
    final service = _Coupons();
    await tester.pumpWidget(
      Provider<CouponService>.value(
        value: service,
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

    await tester.enterText(find.byType(TextFormField).at(0), 'SPRING10');
    await tester.enterText(find.byType(TextFormField).at(1), '10');
    await tester.tap(find.text('บันทึก'));
    await tester.pumpAndSettle();

    expect(service.createdCoupon?['code'], 'SPRING10');
    expect(service.createdCoupon?['discount_value'], 10.0);
  });

  testWidgets('3. Admin filters coupons by status and discount type', (
    tester,
  ) async {
    final service = _Coupons();
    service.coupons = [
      _coupon(1, 'SAVE10', true),
      _coupon(2, 'OLD20', false, discountType: 'percent'),
    ];

    await tester.pumpWidget(
      Provider<CouponService>.value(
        value: service,
        child: const MaterialApp(home: CouponView()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'เปิดใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('แสดง 1 จาก 2 รายการ'), findsOneWidget);
    expect(find.text('SAVE10'), findsOneWidget);
    expect(find.text('OLD20'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'ปิดใช้งาน'));
    await tester.pumpAndSettle();
    expect(find.text('OLD20'), findsOneWidget);
    expect(find.text('SAVE10'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'ทั้งหมด'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'ลดเป็นเปอร์เซ็นต์'));
    await tester.pumpAndSettle();
    expect(find.text('OLD20'), findsOneWidget);
    expect(find.text('SAVE10'), findsNothing);
  });

  testWidgets('4. Admin can turn a coupon off', (tester) async {
    final service = _Coupons();
    service.coupons = [_coupon(1, 'SAVE10', true)];

    await tester.pumpWidget(
      Provider<CouponService>.value(
        value: service,
        child: const MaterialApp(home: CouponView()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(service.statusChanges, [(1, false)]);
  });
}

CouponModel _coupon(
  int id,
  String code,
  bool active, {
  String discountType = 'fixed',
}) => CouponModel(
  couponId: id,
  code: code,
  discountType: discountType,
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
  Map<String, dynamic>? createdCoupon;
  final List<(int, bool)> statusChanges = [];

  @override
  Future<List<CouponModel>> getAllCoupons() async => coupons;

  @override
  Future<void> createCoupon(Map<String, dynamic> body) async {
    createdCoupon = body;
  }

  @override
  Future<void> updateCouponStatus(int couponId, bool isActive) async {
    statusChanges.add((couponId, isActive));
  }
}
