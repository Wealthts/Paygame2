import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/point_view.dart';

// Widget tests for the customer My Points page.
// The fake service returns a balance and history from memory and counts calls.

PointModel _point(int id, int delta, {int? orderId}) => PointModel(
  pointTransactionId: id,
  userId: 10,
  orderId: orderId,
  eventKey: orderId == null ? 'ADMIN_$id' : 'ORDER_$orderId',
  type: delta > 0 ? 'Earn' : 'Spend',
  pointsDelta: delta,
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// Fake PointService.
/// - [calls]: number of page loads (getMyPoints calls).
/// - [failOnCalls]: load numbers (1-based) that throw an ApiException.
class _FakePointService extends PointService {
  _FakePointService({
    this.balance = 0,
    this.history = const [],
    this.failOnCalls = const {},
  }) : super(ApiService());

  final int balance;
  final List<PointModel> history;
  final Set<int> failOnCalls;
  int calls = 0;

  @override
  Future<int> getMyPoints() async {
    calls++;
    if (failOnCalls.contains(calls)) {
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return balance;
  }

  @override
  Future<List<PointModel>> getMyPointHistory() async => List.of(history);
}

/// Opens the points page (tall screen so every row is built).
Future<void> _pump(WidgetTester tester, _FakePointService service) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PointService>.value(
      value: service,
      child: const MaterialApp(home: CustomerPointView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows balance with thousands separator', (tester) async {
    await _pump(tester, _FakePointService(balance: 1250));

    expect(find.text('แต้มสะสมของฉัน'), findsOneWidget);
    expect(find.text('แต้มสะสมคงเหลือ'), findsOneWidget);
    expect(find.text('1,250'), findsOneWidget);
  });

  testWidgets('summary adds up earned and spent from history', (tester) async {
    await _pump(
      tester,
      _FakePointService(
        balance: 70,
        history: [_point(1, 80, orderId: 15), _point(2, -15), _point(3, 5)],
      ),
    );

    expect(find.text('ได้รับทั้งหมด'), findsOneWidget);
    expect(find.text('+85'), findsOneWidget);
    expect(find.text('ใช้ไปทั้งหมด'), findsOneWidget);
    expect(find.text('-15'), findsNWidgets(2)); // summary + history row
  });

  testWidgets('history rows show type, source and signed points', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakePointService(history: [_point(1, 25, orderId: 17), _point(2, -10)]),
    );

    expect(find.text('ประวัติแต้มสะสม'), findsOneWidget);
    expect(find.text('2 รายการ'), findsOneWidget);

    expect(find.text('ได้รับแต้ม'), findsOneWidget);
    expect(find.text('Order #17'), findsOneWidget);
    expect(find.text('+25'), findsNWidgets(2)); // summary + history row

    expect(find.text('ใช้แต้ม'), findsOneWidget);
    expect(find.text('รายการแต้มทั่วไป'), findsOneWidget);
    expect(find.text('-10'), findsNWidgets(2)); // summary + history row
  });

  testWidgets('shows empty state when there is no history', (tester) async {
    await _pump(tester, _FakePointService(balance: 0));

    expect(find.text('0 รายการ'), findsOneWidget);
    expect(find.text('ยังไม่มีประวัติแต้มสะสม'), findsOneWidget);
    expect(
      find.text('เมื่อคุณได้รับหรือใช้แต้ม รายการจะแสดงที่หน้านี้'),
      findsOneWidget,
    );
  });

  testWidgets('has a shortcut to My Coupons', (tester) async {
    await _pump(tester, _FakePointService());

    expect(find.text('คูปองของฉัน'), findsOneWidget);
    expect(find.byTooltip('เปิดคูปอง'), findsOneWidget);
  });

  group('errors and reload', () {
    testWidgets('load error shows message and Try again reloads', (
      tester,
    ) async {
      final service = _FakePointService(
        balance: 1250,
        history: [_point(1, 25)],
        failOnCalls: {1},
      );
      await _pump(tester, service);

      expect(find.text('ไม่สามารถโหลดข้อมูลแต้มสะสมได้'), findsOneWidget);

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(service.calls, 2);
      expect(find.text('ไม่สามารถโหลดข้อมูลแต้มสะสมได้'), findsNothing);
      expect(find.text('1,250'), findsOneWidget);
    });

    testWidgets('pull to refresh loads points again', (tester) async {
      final service = _FakePointService(balance: 1250);
      await _pump(tester, service);

      // Same callback a pull-down gesture runs.
      tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();

      expect(service.calls, 2);
      expect(find.text('1,250'), findsOneWidget);
    });
  });
}
