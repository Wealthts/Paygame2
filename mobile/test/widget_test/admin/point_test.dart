import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/admin/point_view.dart';

final _earn = PointModel(
  pointTransactionId: 1,
  userId: 10,
  orderId: 17,
  eventKey: 'ORDER_17',
  type: 'Earn',
  pointsDelta: 25,
  username: 'test_player',
  createdAt: DateTime(2026, 1, 2, 12),
);

final _spend = PointModel(
  pointTransactionId: 2,
  userId: 11,
  eventKey: 'MANUAL_SPEND_001',
  type: 'Spend',
  pointsDelta: -10,
  displayName: 'Mocha',
  createdAt: DateTime(2026, 1, 3, 9),
);

class _FakeAdminPointService extends PointService {
  _FakeAdminPointService({
    List<PointModel> transactions = const [],
    this.loadFailTimes = 0,
    this.addError,
  }) : transactions = [...transactions],
       super(ApiService());

  final List<PointModel> transactions;
  int loadFailTimes;
  final ApiException? addError;
  final addCalls = <Map<String, Object>>[];

  @override
  Future<List<PointModel>> getAllTransactions() async {
    if (loadFailTimes > 0) {
      loadFailTimes--;
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return [...transactions];
  }

  @override
  Future<void> addPoints({
    required int userId,
    required int points,
    required String eventKey,
  }) async {
    addCalls.add({'userId': userId, 'points': points, 'eventKey': eventKey});
    if (addError != null) throw addError!;
    transactions.add(
      PointModel(
        pointTransactionId: 99,
        userId: userId,
        eventKey: eventKey,
        type: 'Earn',
        pointsDelta: points,
      ),
    );
  }
}

Future<void> _pumpView(WidgetTester tester, PointService service) async {
  // Tall surface so every card in the lazy ListView is built and tappable.
  tester.view.physicalSize = const Size(800, 1600);
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

Future<void> _submitAddPoints(
  WidgetTester tester, {
  required String userId,
  required String points,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.widgetWithText(TextFormField, 'User ID'), userId);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Points'),
    points,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Add points'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('admin points shows summary totals and transaction cards', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminPointService(transactions: [_earn, _spend]),
    );

    expect(find.text('Points Management'), findsOneWidget);
    expect(find.text('Showing 2 of 2 items'), findsOneWidget);
    // Summary: 2 transactions, earned 25, spent 10 (shown as positive).
    expect(find.text('2'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    expect(find.text('+25 points'), findsOneWidget);
    expect(find.text('-10 points'), findsOneWidget);
    expect(find.text('test_player'), findsOneWidget);
    expect(find.text('Mocha'), findsOneWidget);
    expect(find.text('From order system'), findsOneWidget);
    expect(find.text('Added by admin'), findsOneWidget);
  });

  testWidgets('admin points type filter shows only spend transactions', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminPointService(transactions: [_earn, _spend]),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'Spent'));
    await tester.pump();

    expect(find.text('Showing 1 of 2 items'), findsOneWidget);
    expect(find.text('Transaction #2'), findsOneWidget);
    expect(find.text('Transaction #1'), findsNothing);
  });

  testWidgets('admin points search shows no-result state and clears', (
    tester,
  ) async {
    await _pumpView(
      tester,
      _FakeAdminPointService(transactions: [_earn, _spend]),
    );

    await tester.enterText(find.byType(TextField), 'mocha');
    await tester.pump();
    expect(find.text('Transaction #2'), findsOneWidget);
    expect(find.text('Transaction #1'), findsNothing);

    await tester.enterText(find.byType(TextField), 'nobody');
    await tester.pump();
    expect(find.text('No point history matches your search'), findsOneWidget);

    await tester.tap(find.text('Clear search and filters'));
    await tester.pump();
    expect(find.text('Showing 2 of 2 items'), findsOneWidget);
  });

  testWidgets('add points dialog validates empty and zero input', (
    tester,
  ) async {
    final service = _FakeAdminPointService(transactions: [_earn]);
    await _pumpView(tester, service);

    await _submitAddPoints(tester, userId: '', points: '0');

    expect(find.text('Please enter a valid User ID'), findsOneWidget);
    expect(find.text('Points must be a whole number greater than 0'), findsOneWidget);
    expect(service.addCalls, isEmpty);
  });

  testWidgets('add points sends request, reloads list and shows success', (
    tester,
  ) async {
    final service = _FakeAdminPointService(transactions: [_earn]);
    await _pumpView(tester, service);

    await _submitAddPoints(tester, userId: '3', points: '100');

    expect(service.addCalls, hasLength(1));
    expect(service.addCalls.single['userId'], 3);
    expect(service.addCalls.single['points'], 100);
    expect(service.addCalls.single['eventKey'], startsWith('ADMIN_3_'));

    expect(find.text('Points added successfully'), findsOneWidget);
    expect(find.text('Transaction #99'), findsOneWidget);
    expect(find.text('Showing 2 of 2 items'), findsOneWidget);
  });

  testWidgets('add points shows API error message on failure', (tester) async {
    final service = _FakeAdminPointService(
      transactions: [_earn],
      addError: const ApiException(statusCode: 404, message: 'User not found'),
    );
    await _pumpView(tester, service);

    await _submitAddPoints(tester, userId: '999', points: '5');

    expect(find.text('User not found'), findsWidgets);
    expect(find.text('Showing 1 of 1 items'), findsOneWidget);
  });

  testWidgets('admin points shows empty state', (tester) async {
    await _pumpView(tester, _FakeAdminPointService());

    expect(find.text('No point history yet'), findsOneWidget);
  });

  testWidgets('admin points shows API error and retries', (tester) async {
    await _pumpView(
      tester,
      _FakeAdminPointService(transactions: [_spend], loadFailTimes: 1),
    );

    expect(find.text('Server down'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Server down'), findsNothing);
    expect(find.text('Transaction #2'), findsOneWidget);
  });
}
