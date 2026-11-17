import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_history_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('payment history displays payment returned from service', (tester) async {
    await tester.pumpWidget(
      Provider<PaymentService>(
        create: (_) => FakePaymentService(),
        child: const MaterialApp(home: PaymentHistoryView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ประวัติการชำระเงิน'), findsOneWidget);
    expect(find.text('TX-TEST-001'), findsOneWidget);
  });
}