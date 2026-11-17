import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('payment page requests method and transaction reference', (tester) async {
    await tester.pumpWidget(
      Provider<PaymentService>(
        create: (_) => FakePaymentService(),
        child: const MaterialApp(
          home: CustomerPaymentView(
            orderId: 17,
            amount: 159,
            gameName: 'Arena Test',
            packageName: '500 Diamonds',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ช่องทางการชำระเงิน'), findsOneWidget);
    expect(find.textContaining('Transaction Ref'), findsOneWidget);
  });
}