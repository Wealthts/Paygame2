import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/user_coupon_controller.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/service/user_coupon_service.dart';

void main() {
  // These tests cover whether a customer's coupon is ready, used, or unavailable.
  test('CustomerCouponModel identifies an assigned coupon and discount', () {
    final coupon = CustomerCouponModel.fromJson({
      'user_coupon_id': 11,
      'coupon_id': 6,
      'code': 'WELCOME5',
      'discount_type': 'percent',
      'discount_value': '5',
      'min_order_amount': 100,
      'max_discount_amount': 30,
      'start_date': '2026-01-01T00:00:00.000Z',
      'end_date': '2099-12-31T23:59:59.000Z',
      'used_at': null,
      'is_active': 1,
    });

    expect(coupon.userCouponId, 11);
    expect(coupon.discountLabel, '5%');
    expect(coupon.isUsed, isFalse);
    expect(coupon.isAvailable, isTrue);
  });

  test(
    'CustomerCouponModel reports used, inactive, expired, and future coupons',
    () {
      final base = <String, dynamic>{
        'user_coupon_id': 1,
        'coupon_id': 2,
        'code': 'STATUS',
        'discount_type': 'fixed',
        'discount_value': 20,
        'start_date': '2020-01-01T00:00:00.000Z',
        'end_date': '2020-12-31T23:59:59.000Z',
        'is_active': 1,
      };
      expect(CustomerCouponModel.fromJson(base).statusLabel, 'หมดอายุ');
      expect(
        CustomerCouponModel.fromJson({...base, 'used_at': '2020-05-01'})
            .statusLabel,
        'ใช้แล้ว',
      );
      expect(
        CustomerCouponModel.fromJson({...base, 'is_active': 0}).statusLabel,
        'ปิดใช้งาน',
      );
      expect(
        CustomerCouponModel.fromJson({
          ...base,
          'start_date': '2099-01-01',
          'end_date': '2099-12-31',
        }).statusLabel,
        'ยังไม่เริ่มใช้',
      );
    },
  );

  // The fake API lets us check the endpoint and payload without contacting the server.
  test(
    'UserCouponService validates and parses admin and customer results',
    () async {
      final api = _UserCouponApi();
      final service = UserCouponService(api);
      api.getResponse = {
        'user_coupons': [_assignmentJson()],
      };
      expect((await service.getAllUserCoupons()).single.code, 'WELCOME');
      api.getResponse = {
        'users': [
          {'user_id': 3, 'username': 'sam', 'display_name': 'Sam'},
        ],
      };
      expect((await service.getAvailableUsers()).single.label, 'Sam (@sam)');
      api.getResponse = [_customerJson()];
      expect((await service.getMyCoupons()).single.userCouponId, 5);
      api.getResponse = {'bad': true};
      await expectLater(service.getMyCoupons(), throwsFormatException);
    },
  );

  test(
    'UserCouponService normalizes claim codes and assigns coupons',
    () async {
      final api = _UserCouponApi();
      final service = UserCouponService(api);
      await service.claimCouponByCode('  save10 ');
      expect(api.lastPath, '/api/user-coupons/claim');
      expect(api.lastBody, {'code': 'SAVE10'});
      await service.assignCoupon(userId: 8, couponId: 9);
      expect(api.lastPath, '/api/admin/user-coupons');
      expect(api.lastBody, {'user_id': 8, 'coupon_id': 9});
    },
  );

  // The controller loads assignments, counts used coupons, and assigns a coupon.
  test('UserCouponController loads and counts assignments and filters assignable coupons', () async {
    final userService = _FakeUserCouponService()
      ..assignments = [_assignment(1, null), _assignment(2, '2026-03-01')];
    final couponService = _FakeCouponService()
      ..coupons = [_coupon(1, true), _coupon(2, false)];
    final controller = UserCouponController(userService, couponService);
    await controller.loadData();
    expect(controller.totalAssignments, 2);
    expect(controller.unusedAssignments, 1);
    expect(controller.usedAssignments, 1);
    expect(controller.availableCoupons.map((e) => e.couponId), [1]);
    expect(controller.users.single.userId, 8);
    controller.dispose();
  });

  test('UserCouponController assigns and reloads; records errors', () async {
    final userService = _FakeUserCouponService();
    final couponService = _FakeCouponService();
    final controller = UserCouponController(userService, couponService);
    await controller.assignCoupon(userId: 8, couponId: 3);
    expect(userService.assigned, [(8, 3)]);
    expect(controller.isSaving, isFalse);
    expect(userService.loadCount, 1);

    userService.assignError = StateError('assignment failed');
    await expectLater(
      controller.assignCoupon(userId: 8, couponId: 3),
      throwsStateError,
    );
    expect(controller.errorMessage, contains('assignment failed'));
    expect(controller.isSaving, isFalse);
    controller.dispose();
  });
}

Map<String, dynamic> _assignmentJson() => {
  'user_coupon_id': 1,
  'user_id': 8,
  'coupon_id': 3,
  'username': 'sam',
  'display_name': 'Sam',
  'email': 'sam@example.com',
  'code': 'WELCOME',
  'discount_type': 'percent',
  'discount_value': 5,
  'start_date': '2026-01-01',
  'end_date': '2099-12-31',
  'coupon_is_active': 1,
};

// Small response examples used by the service tests above.
Map<String, dynamic> _customerJson() => {
  'user_coupon_id': 5,
  'coupon_id': 2,
  'code': 'CUSTOMER',
  'discount_type': 'percent',
  'discount_value': 10,
  'start_date': '2026-01-01',
  'end_date': '2099-12-31',
  'is_active': 1,
};

UserCouponModel _assignment(int id, String? usedAt) => UserCouponModel(
  userCouponId: id,
  userId: 8,
  couponId: 3,
  username: 'sam',
  displayName: 'Sam',
  email: 'sam@example.com',
  code: 'WELCOME',
  discountType: 'fixed',
  discountValue: 10,
  minOrderAmount: 0,
  maxDiscountAmount: null,
  startDate: '2026-01-01',
  endDate: '2099-12-31',
  usedAt: usedAt,
  couponIsActive: true,
);

CouponModel _coupon(int id, bool active) => CouponModel(
  couponId: id,
  code: 'C$id',
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

class _UserCouponApi extends ApiService {
  dynamic getResponse = [];
  String? lastPath;
  Object? lastBody;
  @override
  Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    lastPath = path;
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) async {
    lastPath = path;
    lastBody = body;
    return {};
  }
}

// Returns fixed test data instead of calling the real API.
class _FakeUserCouponService extends UserCouponService {
  _FakeUserCouponService() : super(ApiService());
  List<UserCouponModel> assignments = [];
  Object? assignError;
  int loadCount = 0;
  final List<(int, int)> assigned = [];
  @override
  Future<List<UserCouponModel>> getAllUserCoupons() async {
    loadCount++;
    return assignments;
  }

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
    if (assignError != null) throw assignError!;
    assigned.add((userId, couponId));
  }
}

class _FakeCouponService extends CouponService {
  _FakeCouponService() : super(ApiService());
  List<CouponModel> coupons = [];
  @override
  Future<List<CouponModel>> getAllCoupons() async => coupons;
}
