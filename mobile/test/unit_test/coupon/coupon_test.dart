import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/coupon_model.dart';

void main() {
  test('CouponModel parses coupon values from the API', () {
    final coupon = CouponModel.fromJson({
      'coupon_id': '7',
      'code': 'SAVE10',
      'discount_type': 'percent',
      'discount_value': '10',
      'min_order_amount': '100',
      'max_discount_amount': '50',
      'use_limit': null,
      'use_count': 3,
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'is_active': '1',
    });

    expect(coupon.couponId, 7);
    expect(coupon.code, 'SAVE10');
    expect(coupon.discountLabel, '10%');
    expect(coupon.usageLabel, '3 / ไม่จำกัด');
    expect(coupon.isActive, isTrue);
  });
}
