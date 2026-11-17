import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/receipt_history_view.dart';

import '../../support/fake_services.dart';

void main() {
  testWidgets('receipt history displays receipt number', (tester) async {
    await tester.pumpWidget(
      Provider<ReceiptService>(
        create: (_) => FakeReceiptService(),
        child: const MaterialApp(home: CustomerReceiptHistoryView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ประวัติใบเสร็จ'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
  });
}