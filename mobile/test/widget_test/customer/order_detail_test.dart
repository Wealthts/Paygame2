import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/view/customer/order_details_view.dart';

OrderModel _order({String status = 'Pending', String? paymentStatus}) {
  return OrderModel(
    orderId: 17,
    userId: 10,
    packageId: 2,
    playerUid: '123456789',
    serverCode: 'TH1',
    gameName: 'Arena Test',
    packageName: '500 Diamonds',
    status: status,
    paymentStatus: paymentStatus,
    originalPrice: 159,
    discountAmount: 10,
    totalAmount: 149,
    couponDiscount: 5,
    feeAmount: 0,
    spentPoints: 20,
    createdAt: DateTime(2026, 1, 2, 12, 5),
  );
}

class _FakeOrderService extends OrderService {
  _FakeOrderService() : super(ApiService());

  Object? cancelError;
  int cancelCalls = 0;

  @override
  Future<void> cancelMyOrder(int orderId) async {
    cancelCalls++;
    if (cancelError != null) throw cancelError!;
  }
}

Future<void> _pumpDetails(
  WidgetTester tester,
  OrderModel order,
  _FakeOrderService service,
) async {
  tester.view.physicalSize = const Size(800, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<OrderService>.value(
      value: service,
      child: MaterialApp(home: CustomerOrderDetailsView(order: order)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows order and player details', (tester) async {
    await _pumpDetails(
      tester,
      _order(paymentStatus: 'Pending'),
      _FakeOrderService(),
    );

    expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
    expect(find.text('ข้อมูลคำสั่งซื้อ'), findsOneWidget);
    expect(find.text('ข้อมูลผู้เล่น'), findsOneWidget);
    expect(find.text('123456789'), findsOneWidget);
    expect(find.text('TH1'), findsOneWidget);
    expect(find.text('฿149.00'), findsOneWidget);
  });

  testWidgets('shows payment button for unpaid Pending order', (tester) async {
    await _pumpDetails(tester, _order(), _FakeOrderService());

    expect(find.text('แจ้งการชำระเงิน'), findsOneWidget);
    expect(find.text('ยกเลิกคำสั่งซื้อ'), findsOneWidget);
  });

  testWidgets('hides cancellation when payment is Paid', (tester) async {
    await _pumpDetails(
      tester,
      _order(status: 'Pending', paymentStatus: 'Paid'),
      _FakeOrderService(),
    );

    expect(find.text('ยกเลิกคำสั่งซื้อ'), findsNothing);
  });

  testWidgets('cancelling an order calls service and closes details', (
    tester,
  ) async {
    final service = _FakeOrderService();
    await _pumpDetails(tester, _order(paymentStatus: 'Pending'), service);

    await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยันยกเลิก'));
    await tester.pumpAndSettle();

    expect(service.cancelCalls, 1);
  });

  testWidgets('shows error after cancellation fails', (tester) async {
    final service = _FakeOrderService()
      ..cancelError = const ApiException(
        statusCode: 500,
        message: 'ไม่สามารถยกเลิกได้',
      );
    await _pumpDetails(tester, _order(paymentStatus: 'Pending'), service);

    await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ยืนยันยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ไม่สามารถยกเลิกคำสั่งซื้อได้'), findsOneWidget);
    expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
  });
}
