import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/receipt_history_view.dart';

import '../../support/fake_services.dart';

class _ConfigurableReceiptService extends ReceiptService {
  _ConfigurableReceiptService({this.receipts = const [], this.failTimes = 0})
    : super(ApiService());

  final List<ReceiptModel> receipts;
  int failTimes;

  @override
  Future<List<ReceiptModel>> getMyReceipts() async {
    if (failTimes > 0) {
      failTimes--;
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return receipts;
  }
}

Future<void> _pumpHistory(WidgetTester tester, ReceiptService service) async {
  await tester.pumpWidget(
    Provider<ReceiptService>.value(
      value: service,
      child: const MaterialApp(home: CustomerReceiptHistoryView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('receipt history displays receipt number', (tester) async {
    await tester.pumpWidget(
      Provider<ReceiptService>(
        create: (_) => FakeReceiptService(),
        child: const MaterialApp(home: CustomerReceiptHistoryView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Receipt History'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
  });

  testWidgets('tapping a receipt opens its details page', (tester) async {
    await _pumpHistory(
      tester,
      _ConfigurableReceiptService(receipts: [testReceipt]),
    );

    await tester.tap(find.text('PG-TEST-0005'));
    await tester.pumpAndSettle();

    expect(find.text('Receipt Details'), findsOneWidget);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
    expect(find.text('#17'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
  });

  testWidgets('receipt history shows empty state', (tester) async {
    await _pumpHistory(tester, _ConfigurableReceiptService());

    expect(find.text('No receipts yet'), findsOneWidget);
  });

  testWidgets('receipt history shows error and retries', (tester) async {
    await _pumpHistory(
      tester,
      _ConfigurableReceiptService(receipts: [testReceipt], failTimes: 1),
    );

    expect(find.text('Could not load receipt history'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load receipt history'), findsNothing);
    expect(find.text('PG-TEST-0005'), findsOneWidget);
  });
}
