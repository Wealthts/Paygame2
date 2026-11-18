import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_view.dart';

import '../../support/fake_services.dart';

// Widget test ฟอร์ม "แจ้งการชำระเงิน" ฝั่ง customer

/// PaymentService ปลอม: เก็บข้อมูลที่ฟอร์มส่งมาไว้ใน [requests]
/// ตั้ง [error] เพื่อจำลองว่า server ตอบ error
class _FakeCreatePaymentService extends PaymentService {
  _FakeCreatePaymentService() : super(ApiService());

  Object? error;
  final requests = <Map<String, Object>>[];

  @override
  Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required String transactionRef,
    required String method,
  }) async {
    requests.add({
      'orderId': orderId,
      'transactionRef': transactionRef,
      'method': method,
    });
    if (error != null) throw error!;
    return {'payment_id': 42, 'status': 'Pending'};
  }
}

Future<void> _pump(
  WidgetTester tester,
  _FakeCreatePaymentService service,
) async {
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PaymentService>.value(
      value: service,
      child: const MaterialApp(
        home: CustomerPaymentView(
          orderId: 17,
          amount: 159,
          gameName: 'Arena Test',
          packageName: '500 Diamonds',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ช่องที่ 1 = ช่องทางชำระเงิน, ช่องที่ 2 = เลขอ้างอิง (Transaction Ref)
Finder get _methodField => find.byType(TextFormField).at(0);
Finder get _refField => find.byType(TextFormField).at(1);
final _submit = find.text('ยืนยันข้อมูลการชำระเงิน');

void main() {
  // เทสต์เดิม: หน้าแสดงช่องกรอกช่องทางและเลขอ้างอิง
  testWidgets('payment page requests method and transaction reference', (
    tester,
  ) async {
    await tester.pumpWidget(
      Provider<PaymentService>(
        create: (_) => FakePaymentService(),
        child: const MaterialApp(
          home: CustomerPaymentView(
            orderId: 17,
            amount: 159,
            gameName: 'Arena Test',
            packageName: '500 Diamonds',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ช่องทางการชำระเงิน'), findsOneWidget);
    expect(find.textContaining('Transaction Ref'), findsOneWidget);
  });

  testWidgets('shows the order being paid', (tester) async {
    await _pump(tester, _FakeCreatePaymentService());

    expect(find.text('#17'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });

  testWidgets('empty form shows errors and sends nothing', (tester) async {
    final service = _FakeCreatePaymentService();
    await _pump(tester, service);

    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('กรุณาระบุช่องทางการชำระเงิน'), findsOneWidget);
    expect(find.text('กรุณากรอกเลขอ้างอิงการชำระเงิน'), findsOneWidget);
    expect(service.requests, isEmpty);
  });

  testWidgets('valid form sends data and shows success', (tester) async {
    final service = _FakeCreatePaymentService();
    await _pump(tester, service);

    await tester.enterText(_methodField, 'PromptPay');
    await tester.enterText(_refField, ' TX-777 ');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(service.requests.single, {
      'orderId': 17,
      'transactionRef': 'TX-777', // ตัดช่องว่างหน้า-หลังแล้ว
      'method': 'PromptPay',
    });
    expect(find.text('บันทึกข้อมูลสำเร็จ'), findsOneWidget);
  });

  testWidgets('server error shows a message and keeps the form', (
    tester,
  ) async {
    final service = _FakeCreatePaymentService()
      ..error = const ApiException(statusCode: 404, message: 'x');
    await _pump(tester, service);

    await tester.enterText(_methodField, 'PromptPay');
    await tester.enterText(_refField, 'TX-1');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('ไม่พบคำสั่งซื้อของคุณ'), findsOneWidget);
    expect(_submit, findsOneWidget); // ยังกดส่งใหม่ได้
  });
}
