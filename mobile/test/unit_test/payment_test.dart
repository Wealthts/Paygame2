import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/payment_model.dart';

void main() {
  test('PaymentModel parses payment and optional snapshot fields', () {
    final payment = PaymentModel.fromJson({
      'payment_id': 5,
      'order_id': '15',
      'transaction_ref': 'TX-123',
      'method': 'PromptPay',
      'amount': '250.75',
      'status': 'Pending',
      'game_name_snapshot': 'Game C',
      'package_name_snapshot': 'Starter Pack',
      'created_at': '2026-09-12T11:00:00Z',
    });

    expect(payment.paymentId, 5);
    expect(payment.orderId, 15);
    expect(payment.amount, 250.75);
    expect(payment.gameName, 'Game C');
    expect(payment.paidAt, isNull);
  });
}
