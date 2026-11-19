import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/receipt_history_view.dart';

// Widget tests for the customer Receipt History page.
// The fake service returns receipts from memory and counts calls in [calls].

ReceiptModel _receipt(
  int id, {
  double? total = 159,
  String? game = 'Arena Test',
  String? package = '500 Diamonds',
}) => ReceiptModel(
  receiptId: id,
  orderId: 100 + id,
  receiptNumber: 'RCP_${100 + id}',
  issuedAt: DateTime(2026, 1, 2, 12, 5),
  gameName: game,
  packageName: package,
  totalAmount: total,
);

/// Fake ReceiptService.
/// - [calls]: number of times getMyReceipts was called.
/// - [failOnCalls]: call numbers (1-based) that throw an ApiException.
class _FakeReceiptService extends ReceiptService {
  _FakeReceiptService(this.receipts, {this.failOnCalls = const {}})
    : super(ApiService());

  final List<ReceiptModel> receipts;
  final Set<int> failOnCalls;
  int calls = 0;

  @override
  Future<List<ReceiptModel>> getMyReceipts() async {
    calls++;
    if (failOnCalls.contains(calls)) {
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return List.of(receipts);
  }
}

/// Opens the history page (tall screen so every card is built).
Future<void> _pump(WidgetTester tester, _FakeReceiptService service) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<ReceiptService>.value(
      value: service,
      child: const MaterialApp(home: CustomerReceiptHistoryView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('summary shows receipt count and total amount', (tester) async {
    await _pump(
      tester,
      _FakeReceiptService([_receipt(1), _receipt(2, total: 40.5)]),
    );

    expect(find.text('ประวัติใบเสร็จ'), findsOneWidget);
    expect(find.text('จำนวนใบเสร็จ'), findsOneWidget);
    expect(find.text('2 รายการ'), findsOneWidget);
    expect(find.text('ยอดรวม'), findsOneWidget);
    expect(find.text('฿199.50'), findsOneWidget);
  });

  testWidgets('each card shows receipt number, game, package and amount', (
    tester,
  ) async {
    await _pump(tester, _FakeReceiptService([_receipt(1)]));

    expect(find.text('RCP_101'), findsOneWidget);
    expect(find.text('#101'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
    expect(find.text('02/01/2026 12:05'), findsOneWidget);
    expect(find.text('ยอดชำระ'), findsOneWidget);
    expect(find.text('แตะเพื่อดูรายละเอียด'), findsOneWidget);
  });

  testWidgets('missing game, package and amount show safe defaults', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeReceiptService([_receipt(1, total: null, game: null, package: null)]),
    );

    expect(find.text('-'), findsNWidgets(2));
    expect(find.text('฿0.00'), findsWidgets);
  });

  testWidgets('shows empty state when there are no receipts', (tester) async {
    await _pump(tester, _FakeReceiptService([]));

    expect(find.text('ยังไม่มีใบเสร็จ'), findsOneWidget);
    expect(
      find.text('ใบเสร็จจะแสดงที่หน้านี้เมื่อระบบออกใบเสร็จให้แล้ว'),
      findsOneWidget,
    );
  });

  testWidgets('load error shows message and Try again reloads', (
    tester,
  ) async {
    final service = _FakeReceiptService([_receipt(1)], failOnCalls: {1});
    await _pump(tester, service);

    expect(find.text('ไม่สามารถโหลดประวัติใบเสร็จได้'), findsOneWidget);

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('ไม่สามารถโหลดประวัติใบเสร็จได้'), findsNothing);
    expect(find.text('RCP_101'), findsOneWidget);
  });

  testWidgets('pull to refresh calls the service again', (tester) async {
    final service = _FakeReceiptService([_receipt(1)]);
    await _pump(tester, service);

    // Same callback a pull-down gesture runs.
    tester.state<RefreshIndicatorState>(find.byType(RefreshIndicator)).show();
    await tester.pumpAndSettle();

    expect(service.calls, 2);
  });

  testWidgets('tapping a card opens the details page', (tester) async {
    await _pump(tester, _FakeReceiptService([_receipt(1)]));

    await tester.tap(find.text('RCP_101'));
    await tester.pumpAndSettle();

    expect(find.text('รายละเอียดใบเสร็จ'), findsOneWidget);
    expect(find.text('ยอดชำระสุทธิ'), findsOneWidget);
  });
}
