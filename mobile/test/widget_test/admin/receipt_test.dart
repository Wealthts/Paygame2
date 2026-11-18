import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/admin/receipt_view.dart';

import '../../support/theme_widget_test_helper.dart';

// Widget tests for the admin Receipts Management page.
// The fake service keeps receipts in memory and records every call in [calls].

ReceiptModel _receipt(int id, {required DateTime issuedAt, int? orderId}) =>
    ReceiptModel(
      receiptId: id,
      orderId: orderId ?? 100 + id,
      receiptNumber: 'RCP_${orderId ?? 100 + id}',
      issuedAt: issuedAt,
    );

// shortcut: "now" receipts can land on yesterday if the test runs exactly at midnight.
final _now = DateTime.now().subtract(const Duration(seconds: 1));
final _fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
final _twentyDaysAgo = DateTime.now().subtract(const Duration(days: 20));
final _longAgo = DateTime(2020, 3, 4, 10, 30);

/// Fake ReceiptService.
/// - [calls]: number of times getAllReceipts was called.
/// - [failOnCalls]: call numbers (1-based) that throw an ApiException.
class _FakeAdminReceiptService extends ReceiptService {
  _FakeAdminReceiptService(this.receipts, {this.failOnCalls = const {}})
    : super(ApiService());

  final List<ReceiptModel> receipts;
  final Set<int> failOnCalls;
  int calls = 0;

  @override
  Future<List<ReceiptModel>> getAllReceipts() async {
    calls++;
    if (failOnCalls.contains(calls)) {
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return List.of(receipts);
  }
}

/// Opens ReceiptView with the fake service (tall screen so every card is built).
Future<void> _pump(WidgetTester tester, _FakeAdminReceiptService service) async {
  tester.view.physicalSize = const Size(900, 2400);
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

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

void main() {
  // Existing check: app theme contract
  testPayGameThemeContract('Admin receipt management');

  testWidgets('shows summary and a card per receipt', (tester) async {
    await _pump(
      tester,
      _FakeAdminReceiptService([
        _receipt(1, issuedAt: _now),
        _receipt(2, issuedAt: _longAgo),
      ]),
    );

    expect(find.text('Receipts Management'), findsOneWidget);
    expect(find.text('ใบเสร็จทั้งหมด'), findsOneWidget);
    expect(find.text('2 รายการ'), findsOneWidget);
    expect(find.text('แสดง 2 จาก 2 รายการ'), findsOneWidget);

    expect(find.text('RCP_101'), findsOneWidget);
    expect(find.text('RCP_102'), findsOneWidget);
    expect(find.text('Receipt ID: 2'), findsOneWidget);
    expect(find.text('Order ID: 102'), findsOneWidget);
    expect(find.text('วันที่ออกใบเสร็จ: 04/03/2020 10:30'), findsOneWidget);
    expect(find.text('ดูรายละเอียด'), findsNWidgets(2));
  });

  testWidgets('shows empty state when there are no receipts', (tester) async {
    await _pump(tester, _FakeAdminReceiptService([]));

    expect(find.text('0 รายการ'), findsOneWidget);
    expect(find.text('ยังไม่มีใบเสร็จรับเงิน'), findsOneWidget);
  });

  // Search field + date chips
  group('filtering', () {
    final receipts = [
      _receipt(1, issuedAt: _now),
      _receipt(2, issuedAt: _fiveDaysAgo),
      _receipt(3, issuedAt: _twentyDaysAgo),
      _receipt(4, issuedAt: _longAgo),
    ];

    testWidgets('search matches receipt number', (tester) async {
      await _pump(tester, _FakeAdminReceiptService(receipts));

      await tester.enterText(find.byType(TextField), 'rcp_104');
      await tester.pump();

      expect(find.text('แสดง 1 จาก 4 รายการ'), findsOneWidget);
      expect(find.text('RCP_104'), findsOneWidget);
      expect(find.text('RCP_101'), findsNothing);
    });

    testWidgets('search matches order id', (tester) async {
      await _pump(tester, _FakeAdminReceiptService(receipts));

      await tester.enterText(find.byType(TextField), '103');
      await tester.pump();

      expect(find.text('Order ID: 103'), findsOneWidget);
      expect(find.text('แสดง 1 จาก 4 รายการ'), findsOneWidget);
    });

    testWidgets('Today / 7 days / 30 days chips narrow the list', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminReceiptService(receipts));

      await tester.tap(_chip('วันนี้'));
      await tester.pump();
      expect(find.text('แสดง 1 จาก 4 รายการ'), findsOneWidget);
      expect(find.text('RCP_101'), findsOneWidget);

      await tester.tap(_chip('7 วันที่ผ่านมา'));
      await tester.pump();
      expect(find.text('แสดง 2 จาก 4 รายการ'), findsOneWidget);
      expect(find.text('RCP_103'), findsNothing);

      await tester.tap(_chip('30 วันที่ผ่านมา'));
      await tester.pump();
      expect(find.text('แสดง 3 จาก 4 รายการ'), findsOneWidget);
      expect(find.text('RCP_104'), findsNothing);

      await tester.tap(_chip('ทั้งหมด'));
      await tester.pump();
      expect(find.text('แสดง 4 จาก 4 รายการ'), findsOneWidget);
    });

    testWidgets('Clear filters resets search and chip', (tester) async {
      await _pump(tester, _FakeAdminReceiptService(receipts));

      expect(find.text('ล้างตัวกรอง'), findsNothing);

      await tester.tap(_chip('วันนี้'));
      await tester.enterText(find.byType(TextField), 'rcp');
      await tester.pump();
      expect(find.text('แสดง 1 จาก 4 รายการ'), findsOneWidget);

      await tester.tap(find.text('ล้างตัวกรอง'));
      await tester.pump();

      expect(find.text('แสดง 4 จาก 4 รายการ'), findsOneWidget);
      expect(find.text('ล้างตัวกรอง'), findsNothing);
    });

    testWidgets('no match shows message and a button to reset', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminReceiptService(receipts));

      await tester.enterText(find.byType(TextField), 'does-not-exist');
      await tester.pump();

      expect(find.text('ไม่พบใบเสร็จที่ตรงกับเงื่อนไข'), findsOneWidget);

      await tester.tap(find.text('ล้างคำค้นหาและตัวกรอง'));
      await tester.pump();

      expect(find.text('แสดง 4 จาก 4 รายการ'), findsOneWidget);
    });
  });

  // Details dialog (read-only)
  group('details dialog', () {
    testWidgets('opens from the card and shows receipt fields', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeAdminReceiptService([
          _receipt(7, orderId: 55, issuedAt: _longAgo),
        ]),
      );

      await tester.tap(find.text('ดูรายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('Receipt Details'), findsOneWidget);
      expect(find.text('Receipt Number'), findsOneWidget);
      expect(find.text('04/03/2020 10:30'), findsOneWidget);
      expect(find.textContaining('ไม่สามารถแก้ไขจากหน้านี้ได้'), findsOneWidget);
    });

    testWidgets('Close dismisses the dialog', (tester) async {
      await _pump(
        tester,
        _FakeAdminReceiptService([_receipt(1, issuedAt: _longAgo)]),
      );

      await tester.tap(find.text('RCP_101'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt Details'), findsOneWidget);

      await tester.tap(find.text('ปิด'));
      await tester.pumpAndSettle();
      expect(find.text('Receipt Details'), findsNothing);
    });
  });

  // Loading errors, retry and refresh
  group('errors and reload', () {
    testWidgets('first load error shows message and Try again reloads', (
      tester,
    ) async {
      final service = _FakeAdminReceiptService([
        _receipt(1, issuedAt: _longAgo),
      ], failOnCalls: {1});
      await _pump(tester, service);

      expect(find.text('Server down'), findsOneWidget);
      expect(find.text('RCP_101'), findsNothing);

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
      expect(find.text('Server down'), findsNothing);
      expect(find.text('RCP_101'), findsOneWidget);
    });

    testWidgets('Refresh button reloads receipts', (tester) async {
      final service = _FakeAdminReceiptService([
        _receipt(1, issuedAt: _longAgo),
      ]);
      await _pump(tester, service);
      expect(service.calls, 1);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
    });

    testWidgets('refresh error keeps old list and shows a banner', (
      tester,
    ) async {
      final service = _FakeAdminReceiptService([
        _receipt(1, issuedAt: _longAgo),
      ], failOnCalls: {2});
      await _pump(tester, service);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('Server down'), findsOneWidget);
      expect(find.text('RCP_101'), findsOneWidget);
    });
  });
}
