import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/coupon_service.dart';

void main() {
  test('CouponService reads coupons and checks the response format', () async {
    final api = _CouponApi()
      ..getResponse = {
        'coupons': [
          {
            'coupon_id': 2,
            'code': 'SAVE',
            'discount_type': 'fixed',
            'discount_value': 10,
            'is_active': 1,
          },
        ],
      };

    final coupons = await CouponService(api).getAllCoupons();
    expect(api.lastPath, '/api/admin/coupons/all');
    expect(coupons.single.code, 'SAVE');

    api.getResponse = {'items': []};
    await expectLater(
      CouponService(api).getAllCoupons(),
      throwsFormatException,
    );
  });

  test('CouponService sends create, update, and status requests', () async {
    final api = _CouponApi();
    final service = CouponService(api);

    await service.createCoupon({'code': 'NEW'});
    expect(api.lastMethod, 'POST');
    expect(api.lastPath, '/api/admin/coupons');
    expect(api.lastBody, {'code': 'NEW'});

    await service.updateCoupon(4, {'code': 'EDIT'});
    expect(api.lastMethod, 'PUT');
    expect(api.lastPath, '/api/admin/coupons/4');

    await service.updateCouponStatus(4, false);
    expect(api.lastMethod, 'PATCH');
    expect(api.lastPath, '/api/admin/coupons/4/status');
    expect(api.lastBody, {'is_active': 0});
  });
}

// Records each request so these tests do not need a running backend.
class _CouponApi extends ApiService {
  dynamic getResponse = {'coupons': []};
  String? lastMethod;
  String? lastPath;
  Object? lastBody;

  @override
  Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    lastMethod = 'GET';
    lastPath = path;
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) async {
    lastMethod = 'POST';
    lastPath = path;
    lastBody = body;
    return {};
  }

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) async {
    lastMethod = 'PUT';
    lastPath = path;
    lastBody = body;
    return {};
  }

  @override
  Future<dynamic> patch(
    String path, {
    Object? body,
    bool requiresAuth = true,
  }) async {
    lastMethod = 'PATCH';
    lastPath = path;
    lastBody = body;
    return {};
  }
}
