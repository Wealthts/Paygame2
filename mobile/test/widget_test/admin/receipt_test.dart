import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/admin/receipt_view.dart';

// shortcut: a receipt issued 1s ago can fall on yesterday if the test runs right at midnight.
final _todayReceipt = ReceiptModel(
  receiptId: 5,
  orderId: 17,
  receiptNumber: 'PG-TEST-0005',
  issuedAt: DateTime.now().subtract(const Duration(seconds: 1)),
);

final _oldReceipt = ReceiptModel(
  receiptId: 6,
  orderId: 18,
  receiptNumber: 'PG-OLD-0006',
  issuedAt: DateTime(2020, 3, 4, 10, 30),
);

class _FakeAdminReceiptService extends ReceiptService {
  _FakeAdminReceiptService({this.receipts = const [], this.failTimes = 0})
    : super(ApiService());

  final List<ReceiptModel> receipts;
  int failTimes;
  int calls = 0;

  @override
  Future<List<ReceiptModel>> getAllReceipts() async {
    calls++;
    if (failTimes > 0) {
      failTimes--;
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return receipts;
  }
}

Future<void> _pumpView(WidgetTester tester, ReceiptService service) async {
  // Tall surface so every card in the lazy ListView is built and tappable.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Provider<ReceiptService>.value(
      value: service,
      child: const MaterialApp(home: ReceiptView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('admin receipts lists every receipt with summary count', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminReceiptService(receipts: [_todayReceipt, _oldReceipt]),
    );

    expect(find.text('Receipts Management'), findsOneWidget);
    expect(find.text('2 items'), findsOneWidget);
    expect(find.text('Showing 2 of 2 items'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
    expect(find.text('PG-OLD-0006'), findsOneWidget);
    expect(find.text('Order ID: 18'), findsOneWidget);
  });

  testWidgets('admin receipts search filters and can be cleared', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminReceiptService(receipts: [_todayReceipt, _oldReceipt]),
    );

    await tester.enterText(find.byType(TextField), 'pg-old');
    await tester.pump();

    expect(find.text('Showing 1 of 2 items'), findsOneWidget);
    expect(find.text('PG-OLD-0006'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsNothing);

    await tester.enterText(find.byType(TextField), 'no-such-receipt');
    await tester.pump();
    expect(find.text('No receipts match your filters'), findsOneWidget);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pump();
    expect(find.text('Showing 2 of 2 items'), findsOneWidget);
  });

  testWidgets('admin receipts "today" filter hides old receipts', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminReceiptService(receipts: [_todayReceipt, _oldReceipt]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Today'));
    await tester.pump();

    expect(find.text('Showing 1 of 2 items'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
    expect(find.text('PG-OLD-0006'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('admin receipt card opens and closes the details dialog', (
    tester,
  ) async {
    await _pumpView(tester, _FakeAdminReceiptService(receipts: [_oldReceipt]));

    await tester.tap(find.text('View details'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Details'), findsOneWidget);
    expect(find.text('04/03/2020 10:30'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Receipt Details'), findsNothing);
  });

  testWidgets('admin receipts shows empty state', (tester) async {
    await _pumpView(tester, _FakeAdminReceiptService());

    expect(find.text('0 items'), findsOneWidget);
    expect(find.text('No receipts yet'), findsOneWidget);
  });

  testWidgets('admin receipts shows API error and retries', (tester) async {
    final service = _FakeAdminReceiptService(
      receipts: [_oldReceipt],
      failTimes: 1,
    );
    await _pumpView(tester, service);

    expect(find.text('Server down'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('Server down'), findsNothing);
    expect(find.text('PG-OLD-0006'), findsOneWidget);
  });
}
