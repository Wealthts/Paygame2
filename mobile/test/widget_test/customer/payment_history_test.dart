import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_history_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "ประวัติการชำระเงิน" ของ customer (ว่าง / มีข้อมูล / error)

PaymentModel _payment(int id, String status, {String ref = 'TX-1'}) =>
    PaymentModel(
      paymentId: id,
      orderId: 200 + id,
      transactionRef: ref,
      method: 'PromptPay',
      amount: 100,
      status: status,
      gameName: 'Arena Test',
      packageName: '500 Diamonds',
      createdAt: DateTime(2026, 1, 2, 12, 5),
    );

/// PaymentService ปลอม
/// - [error] : จำลองโหลดไม่สำเร็จ
class _FakeHistoryService extends PaymentService {
  _FakeHistoryService() : super(ApiService());

  List<PaymentModel> payments = [];
  Object? error;

  @override
  Future<List<PaymentModel>> getMyPayments() async {
    if (error != null) throw error!;
    return List.of(payments);
  }
}

Future<void> _pump(WidgetTester tester, _FakeHistoryService service) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PaymentService>.value(
      value: service,
      child: const MaterialApp(home: PaymentHistoryView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // เทสต์เดิม: แสดงหัวข้อและรายการที่ service ส่งมา
  testWidgets('payment history displays payment returned from service', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<PaymentService>(
        create: (_) => FakePaymentService(),
        child: const MaterialApp(home: PaymentHistoryView()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ประวัติการชำระเงิน'), findsOneWidget);
    expect(find.text('TX-TEST-001'), findsOneWidget);
  });

  testWidgets('empty history shows empty state', (tester) async {
    await _pump(tester, _FakeHistoryService());

    expect(find.text('ยังไม่มีประวัติการชำระเงิน'), findsOneWidget);
  });

  testWidgets('lists payments with reference and status', (tester) async {
    final service = _FakeHistoryService()
      ..payments = [
        _payment(1, 'Pending', ref: 'TX-AAA'),
        _payment(2, 'Paid', ref: 'TX-BBB'),
      ];
    await _pump(tester, service);

    expect(find.text('TX-AAA'), findsOneWidget);
    expect(find.text('TX-BBB'), findsOneWidget);
    expect(find.text('รอตรวจสอบ'), findsWidgets);
    expect(find.text('ชำระแล้ว'), findsWidgets);
  });

  testWidgets('shows error and can retry', (tester) async {
    final service = _FakeHistoryService()
      ..error = const ApiException(statusCode: 500, message: 'down');
    await _pump(tester, service);
    expect(find.text('ไม่สามารถโหลดประวัติการชำระเงินได้'), findsOneWidget);

    service
      ..error = null
      ..payments = [_payment(9, 'Paid', ref: 'TX-RETRY')];
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('TX-RETRY'), findsOneWidget);
  });
}
