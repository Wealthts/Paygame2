import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/user_coupon_model.dart';

void main() {
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
}
