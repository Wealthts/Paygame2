import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/admin/point_view.dart';

import '../../support/theme_widget_test_helper.dart';

// Widget tests for the admin Points Management page.
// The fake service keeps transactions in memory and records calls in [calls].

PointModel _point(
  int id,
  int delta, {
  int userId = 10,
  int? orderId,
  String? username,
  String? displayName,
}) => PointModel(
  pointTransactionId: id,
  userId: userId,
  orderId: orderId,
  eventKey: orderId == null ? 'ADMIN_$id' : 'ORDER_$orderId',
  type: delta > 0 ? 'Earn' : 'Spend',
  pointsDelta: delta,
  username: username,
  displayName: displayName,
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// Fake PointService.
/// - [calls]: methods called, e.g. 'getAll', 'add:3:100'.
/// - [failLoadOnCalls]: getAll call numbers (1-based) that throw.
/// - [addError]: thrown by addPoints when set.
class _FakeAdminPointService extends PointService {
  _FakeAdminPointService(
    List<PointModel> transactions, {
    this.failLoadOnCalls = const {},
    this.addError,
  }) : transactions = List.of(transactions),
       super(ApiService());

  final List<PointModel> transactions;
  final Set<int> failLoadOnCalls;
  final ApiException? addError;
  final calls = <String>[];
  String? lastEventKey;
  int _loads = 0;

  @override
  Future<List<PointModel>> getAllTransactions() async {
    calls.add('getAll');
    _loads++;
    if (failLoadOnCalls.contains(_loads)) {
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return List.of(transactions);
  }

  @override
  Future<void> addPoints({
    required int userId,
    required int points,
    required String eventKey,
  }) async {
    calls.add('add:$userId:$points');
    lastEventKey = eventKey;
    if (addError != null) throw addError!;
    transactions.add(_point(99, points, userId: userId));
  }
}

/// Opens PointView with the fake service (tall screen so every card is built).
Future<void> _pump(WidgetTester tester, _FakeAdminPointService service) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PointService>.value(
      value: service,
      child: const MaterialApp(home: PointView()),
    ),
  );
  await tester.pumpAndSettle();
}

/// Finds text only inside transaction cards (filter chips use the same words).
Finder _inCard(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

Finder _chip(String label) => find.widgetWithText(ChoiceChip, label);

/// Opens the Add points dialog and fills both fields.
Future<void> _fillAddDialog(
  WidgetTester tester, {
  required String userId,
  required String points,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'User ID'), userId);
  await tester.enterText(find.widgetWithText(TextFormField, 'จำนวนแต้ม'), points);
}

Future<void> _submitAddDialog(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'เพิ่มแต้ม'));
  await tester.pumpAndSettle();
}

void main() {
  // Existing check: app theme contract
  testPayGameThemeContract('Admin point management');

  final orderEarn = _point(1, 25, orderId: 17, username: 'test_player');
  final adminSpend = _point(2, -10, userId: 11, displayName: 'Mocha');

  testWidgets('summary shows count, total earned and total spent', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeAdminPointService([orderEarn, adminSpend, _point(3, 5)]),
    );

    expect(find.text('Points Management'), findsOneWidget);
    expect(find.text('ภาพรวมประวัติแต้ม'), findsOneWidget);

    // 3 transactions, earned 25 + 5 = 30, spent 10 (shown without minus)
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'รายการทั้งหมด'),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'แต้มที่ได้รับ'),
        matching: find.text('30'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.widgetWithText(Card, 'แต้มที่ใช้'),
        matching: find.text('10'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('cards show user, source and signed points', (tester) async {
    await _pump(tester, _FakeAdminPointService([orderEarn, adminSpend]));

    expect(find.text('Transaction #1'), findsOneWidget);
    expect(find.text('test_player'), findsOneWidget);
    expect(find.text('Order ID: 17'), findsOneWidget);
    expect(find.text('รายการจากระบบ Order'), findsOneWidget);
    expect(find.text('+25 แต้ม'), findsOneWidget);
    expect(_inCard('ได้รับแต้ม'), findsOneWidget);

    expect(find.text('Mocha'), findsOneWidget);
    expect(find.text('User ID: 11'), findsOneWidget);
    expect(find.text('รายการจาก Admin'), findsOneWidget);
    expect(find.text('-10 แต้ม'), findsOneWidget);
    expect(_inCard('ใช้แต้ม'), findsOneWidget);
  });

  testWidgets('falls back to "User #id" when the user has no name', (
    tester,
  ) async {
    await _pump(tester, _FakeAdminPointService([_point(5, 3, userId: 42)]));

    expect(find.text('User #42'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no transactions', (
    tester,
  ) async {
    await _pump(tester, _FakeAdminPointService([]));

    expect(find.text('ยังไม่มีประวัติแต้ม'), findsOneWidget);
  });

  // Search field + Earned/Spent chips
  group('filtering', () {
    testWidgets('Earned and Spent chips filter by sign', (tester) async {
      await _pump(tester, _FakeAdminPointService([orderEarn, adminSpend]));

      await tester.tap(_chip('ใช้แต้ม'));
      await tester.pump();
      expect(find.text('แสดง 1 จาก 2 รายการ'), findsOneWidget);
      expect(find.text('Transaction #2'), findsOneWidget);
      expect(find.text('Transaction #1'), findsNothing);

      await tester.tap(_chip('ได้รับแต้ม'));
      await tester.pump();
      expect(find.text('Transaction #1'), findsOneWidget);
      expect(find.text('Transaction #2'), findsNothing);

      await tester.tap(_chip('ทั้งหมด'));
      await tester.pump();
      expect(find.text('แสดง 2 จาก 2 รายการ'), findsOneWidget);
    });

    testWidgets('search matches username, display name and event key', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminPointService([orderEarn, adminSpend]));

      await tester.enterText(find.byType(TextField), 'MOCHA');
      await tester.pump();
      expect(find.text('Transaction #2'), findsOneWidget);
      expect(find.text('Transaction #1'), findsNothing);

      await tester.enterText(find.byType(TextField), 'order_17');
      await tester.pump();
      expect(find.text('Transaction #1'), findsOneWidget);
      expect(find.text('Transaction #2'), findsNothing);
    });

    testWidgets('no match shows message and Clear filters resets', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminPointService([orderEarn, adminSpend]));

      await tester.tap(_chip('ใช้แต้ม'));
      await tester.enterText(find.byType(TextField), 'nobody');
      await tester.pump();
      expect(find.text('ไม่พบประวัติแต้มที่ตรงกับการค้นหา'), findsOneWidget);

      await tester.tap(find.text('ล้างคำค้นหาและตัวกรอง'));
      await tester.pump();
      expect(find.text('แสดง 2 จาก 2 รายการ'), findsOneWidget);
      expect(find.text('ล้างตัวกรอง'), findsNothing);
    });
  });

  // Add points dialog
  group('add points', () {
    testWidgets('rejects empty user id and non-positive points', (
      tester,
    ) async {
      final service = _FakeAdminPointService([orderEarn]);
      await _pump(tester, service);

      await _fillAddDialog(tester, userId: '', points: '-5');
      await _submitAddDialog(tester);

      expect(find.text('กรุณากรอก User ID ให้ถูกต้อง'), findsOneWidget);
      expect(
        find.text('จำนวนแต้มต้องเป็นจำนวนเต็มมากกว่า 0'),
        findsOneWidget,
      );
      expect(service.calls, isNot(contains(startsWith('add'))));
    });

    testWidgets('Cancel closes the dialog without saving', (tester) async {
      final service = _FakeAdminPointService([orderEarn]);
      await _pump(tester, service);

      await _fillAddDialog(tester, userId: '3', points: '100');
      await tester.tap(find.text('ยกเลิก'));
      await tester.pumpAndSettle();

      expect(find.text('เพิ่มแต้มให้สมาชิก'), findsNothing);
      expect(service.calls, ['getAll']);
    });

    testWidgets('valid input saves, reloads the list and confirms', (
      tester,
    ) async {
      final service = _FakeAdminPointService([orderEarn]);
      await _pump(tester, service);

      await _fillAddDialog(tester, userId: '3', points: '100');
      await _submitAddDialog(tester);

      expect(service.calls, ['getAll', 'add:3:100', 'getAll']);
      expect(service.lastEventKey, startsWith('ADMIN_3_'));
      expect(find.text('เพิ่มแต้มให้สมาชิกเรียบร้อยแล้ว'), findsOneWidget);
      expect(find.text('Transaction #99'), findsOneWidget);
      expect(find.text('+100 แต้ม'), findsOneWidget);
      expect(find.text('แสดง 2 จาก 2 รายการ'), findsOneWidget);
    });

    testWidgets('API error is shown and the list is unchanged', (tester) async {
      final service = _FakeAdminPointService([
        orderEarn,
      ], addError: const ApiException(statusCode: 404, message: 'User not found'));
      await _pump(tester, service);

      await _fillAddDialog(tester, userId: '999', points: '5');
      await _submitAddDialog(tester);

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.text('User not found'),
        ),
        findsOneWidget,
      );
      expect(find.text('แสดง 1 จาก 1 รายการ'), findsOneWidget);
    });
  });

  // Loading errors, retry and refresh
  group('errors and reload', () {
    testWidgets('first load error shows message and Try again reloads', (
      tester,
    ) async {
      final service = _FakeAdminPointService([
        adminSpend,
      ], failLoadOnCalls: {1});
      await _pump(tester, service);

      expect(find.text('Server down'), findsOneWidget);

      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'getAll']);
      expect(find.text('Server down'), findsNothing);
      expect(find.text('Transaction #2'), findsOneWidget);
    });

    testWidgets('refresh error keeps old list and shows a banner', (
      tester,
    ) async {
      final service = _FakeAdminPointService([
        adminSpend,
      ], failLoadOnCalls: {2});
      await _pump(tester, service);

      await tester.tap(find.byTooltip('Refresh'));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.text('Transaction #2'), findsOneWidget);
    });
  });
}
