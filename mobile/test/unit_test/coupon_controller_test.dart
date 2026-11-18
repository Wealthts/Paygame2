import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/coupon_controller.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/coupon_service.dart';

void main() {
  test('CouponController loads coupons and counts active ones', () async {
    final service = _FakeCouponService();
    service.coupons = [_coupon(1, true), _coupon(2, false)];
    final controller = CouponController(service);

    await controller.loadCoupons();

    expect(controller.totalCoupons, 2);
    expect(controller.activeCoupons, 1);
    expect(controller.inactiveCoupons, 1);
    expect(controller.errorMessage, isNull);
    controller.dispose();
  });

  test(
    'CouponController creates or edits a coupon, then reloads the list',
    () async {
      final service = _FakeCouponService();
      final controller = CouponController(service);

      await controller.saveCoupon(body: {'code': 'NEW'});
      await controller.saveCoupon(couponId: 3, body: {'code': 'EDIT'});

      expect(service.created, 1);
      expect(service.updatedIds, [3]);
      expect(service.loadCount, 2);
      expect(controller.isSaving, isFalse);
      controller.dispose();
    },
  );

  test(
    'CouponController keeps an error message when loading or saving fails',
    () async {
      final service = _FakeCouponService();
      service.loadError = StateError('load failed');
      final controller = CouponController(service);

      await controller.loadCoupons();
      expect(controller.errorMessage, contains('load failed'));

      service.saveError = StateError('save failed');
      await expectLater(controller.saveCoupon(body: {}), throwsStateError);
      expect(controller.errorMessage, contains('save failed'));
      expect(controller.isSaving, isFalse);
      controller.dispose();
    },
  );
}

CouponModel _coupon(int id, bool active) => CouponModel(
  couponId: id,
  code: 'C$id',
  discountType: 'fixed',
  discountValue: 10,
  minOrderAmount: 0,
  maxDiscountAmount: null,
  useLimit: null,
  useCount: 0,
  startDate: '',
  endDate: '',
  isActive: active,
);

// Returns sample coupons and remembers which save methods the controller calls.
class _FakeCouponService extends CouponService {
  _FakeCouponService() : super(ApiService());

  List<CouponModel> coupons = [];
  Object? loadError;
  Object? saveError;
  int created = 0;
  int loadCount = 0;
  final List<int> updatedIds = [];

  @override
  Future<List<CouponModel>> getAllCoupons() async {
    loadCount++;
    if (loadError != null) throw loadError!;
    return coupons;
  }

  @override
  Future<void> createCoupon(Map<String, dynamic> body) async {
    if (saveError != null) throw saveError!;
    created++;
  }

  @override
  Future<void> updateCoupon(int couponId, Map<String, dynamic> body) async {
    if (saveError != null) throw saveError!;
    updatedIds.add(couponId);
  }

  @override
  Future<void> updateCouponStatus(int couponId, bool isActive) async {}
}
