import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/point_model.dart';

void main() {
  test('PointModel parses positive and nullable transaction fields', () {
    final point = PointModel.fromJson({
      'point_transaction_id': '91',
      'user_id': 8,
      'order_id': null,
      'event_key': 'signup_event',
      'type': 'Earn',
      'points_delta': '50',
      'created_at': '2026-08-01T00:00:00Z',
    });

    expect(point.pointTransactionId, 91);
    expect(point.userId, 8);
    expect(point.orderId, isNull);
    expect(point.pointsDelta, 50);
    expect(point.type, 'Earn');
    expect(point.createdAt, isNotNull);
  });
}
