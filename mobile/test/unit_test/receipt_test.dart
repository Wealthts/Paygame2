import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/receipt_model.dart';

void main() {
  test('ReceiptModel parses receipt metadata and total amount', () {
    final receipt = ReceiptModel.fromJson({
      'receipt_id': '13',
      'order_id': 44,
      'receipt_number': 'PG-2026-00013',
      'issued_at': '2026-07-14T09:30:00Z',
      'game_name_snapshot': 'Game D',
      'package_name_snapshot': 'Weekly Pass',
      'total_amount': '299.00',
    });

    expect(receipt.receiptId, 13);
    expect(receipt.orderId, 44);
    expect(receipt.receiptNumber, 'PG-2026-00013');
    expect(receipt.totalAmount, 299);
    expect(receipt.issuedAt, isNotNull);
  });
}
