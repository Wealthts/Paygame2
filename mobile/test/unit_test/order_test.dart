import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/order_model.dart';

void main() {
  test('OrderModel parses prices, snapshots, dates and point usage', () {
    final order = OrderModel.fromJson({
      'order_id': '31',
      'user_id': 4,
      'package_id': 9,
      'player_uid': '99887766',
      'server_code': 'TH-01',
      'game_name_snapshot': 'Game A',
      'package_name_snapshot': '100 Gems',
      'status': 'Completed',
      'payment_status': 'Paid',
      'original_price': '120.00',
      'discount_amount': '10.00',
      'total_amount': '110.00',
      'coupon_discount': '5.00',
      'fee_amount': '0.00',
      'spent_points': '50',
      'created_at': '2026-10-01T10:00:00.000Z',
    });

    expect(order.orderId, 31);
    expect(order.gameName, 'Game A');
    expect(order.totalAmount, 110);
    expect(order.spentPoints, 50);
    expect(order.createdAt, isNotNull);
    expect(order.completedAt, isNull);
  });
}
