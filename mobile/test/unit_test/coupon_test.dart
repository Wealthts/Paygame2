import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/coupon_model.dart';

void main() {
  group('CouponModel', () {
    test('parses a percentage coupon and exposes display labels', () {
      final coupon = CouponModel.fromJson({
        'coupon_id': 7,
        'code': 'SAVE10',
        'discount_type': 'percent',
        'discount_value': '10',
        'min_order_amount': '100',
        'max_discount_amount': '50',
        'use_limit': null,
        'use_count': 3,
        'start_date': '2026-01-01',
        'end_date': '2026-12-31',
        'is_active': 1,
      });

      expect(coupon.couponId, 7);
      expect(coupon.discountLabel, '10%');
      expect(coupon.usageLabel, '3 / ไม่จำกัด');
      expect(coupon.isActive, isTrue);
    });

    test('formats fixed discount as Thai baht', () {
      final coupon = CouponModel.fromJson({
        'coupon_id': '8',
        'code': 'LESS20',
        'discount_type': 'fixed',
        'discount_value': 20,
        'min_order_amount': 0,
        'is_active': 0,
      });
      expect(coupon.discountLabel, '฿20.00');
      expect(coupon.isActive, isFalse);
    });
  });
}
