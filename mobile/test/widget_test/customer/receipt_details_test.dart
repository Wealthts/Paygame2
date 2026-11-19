import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/view/customer/receipt_details_view.dart';

// Widget tests for the customer Receipt Details page.
// The page only shows the receipt it is given, so no service is needed.

final _receipt = ReceiptModel(
  receiptId: 5,
  orderId: 105,
  receiptNumber: 'RCP_105',
  issuedAt: DateTime(2026, 1, 2, 12, 5),
  gameName: 'Arena Test',
  packageName: '500 Diamonds',
  totalAmount: 159,
);

/// Opens the details page (tall screen so every row is built).
Future<void> _pump(WidgetTester tester, ReceiptModel receipt) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(home: CustomerReceiptDetailsView(receipt: receipt)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows every receipt field and the paid total', (tester) async {
    await _pump(tester, _receipt);

    expect(find.text('รายละเอียดใบเสร็จ'), findsOneWidget);
    expect(find.text('ใบเสร็จรับเงิน'), findsOneWidget);
    expect(find.text('เลขที่ใบเสร็จ'), findsOneWidget);
    expect(find.text('RCP_105'), findsOneWidget);
    expect(find.text('5'), findsOneWidget); // Receipt ID
    expect(find.text('#105'), findsOneWidget); // Order ID
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
    expect(find.text('02/01/2026 12:05'), findsOneWidget);
    expect(find.text('ยอดชำระสุทธิ'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });

  testWidgets('has an enabled Print / Save PDF button', (tester) async {
    await _pump(tester, _receipt);

    final button = find.ancestor(
      of: find.text('พิมพ์ / บันทึก PDF'),
      matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
    );
    expect(button, findsOneWidget);
    expect(tester.widget<ButtonStyleButton>(button).enabled, isTrue);
  });
}
