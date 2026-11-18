import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/view/customer/point_view.dart';

import '../../support/fake_services.dart';

class _ConfigurablePointService extends PointService {
  _ConfigurablePointService({
    this.balance = 0,
    this.history = const [],
    this.failTimes = 0,
  }) : super(ApiService());

  final int balance;
  final List<PointModel> history;
  int failTimes;

  @override
  Future<int> getMyPoints() async {
    if (failTimes > 0) {
      failTimes--;
      throw const ApiException(statusCode: 500, message: 'Server down');
    }
    return balance;
  }

  @override
  Future<List<PointModel>> getMyPointHistory() async => history;
}

Future<void> _pumpPoints(WidgetTester tester, PointService service) async {
  await tester.pumpWidget(
    Provider<PointService>.value(
      value: service,
      child: const MaterialApp(home: CustomerPointView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('points page shows current balance and point history', (tester) async {
    await tester.pumpWidget(
      Provider<PointService>(
        create: (_) => FakePointService(),
        child: const MaterialApp(home: CustomerPointView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1,250'), findsOneWidget);
    expect(find.text('Point History'), findsOneWidget);
    expect(find.text('+25'), findsNWidgets(2));
  });

  testWidgets('points page shows spent points as negative', (tester) async {
    await _pumpPoints(
      tester,
      _ConfigurablePointService(
        balance: 15,
        history: [
          testPoint,
          PointModel(
            pointTransactionId: 2,
            userId: 10,
            orderId: 17,
            eventKey: 'ORDER_17_SPEND',
            type: 'Spend',
            pointsDelta: -10,
            createdAt: DateTime(2026, 1, 3, 9),
          ),
        ],
      ),
    );

    expect(find.text('15'), findsWidgets);
    expect(find.text('-10'), findsWidgets);
  });

  testWidgets('points page shows empty history state', (tester) async {
    await _pumpPoints(tester, _ConfigurablePointService());

    expect(find.text('No point history yet'), findsOneWidget);
  });

  testWidgets('points page shows error and retries', (tester) async {
    await _pumpPoints(
      tester,
      _ConfigurablePointService(balance: 1250, history: [testPoint], failTimes: 1),
    );

    expect(find.text('Could not load points'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load points'), findsNothing);
    expect(find.text('1,250'), findsOneWidget);
  });
}
