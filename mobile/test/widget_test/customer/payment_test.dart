import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_view.dart';

import '../../support/fake_services.dart';

// Widget test ฟอร์ม "แจ้งการชำระเงิน" (CustomerPaymentView) ฝั่ง customer

/// PaymentService ปลอม เน้นเมธอด createPayment
/// - [response] : สิ่งที่ "server" ตอบกลับเมื่อสำเร็จ
/// - [error]    : ตั้งไว้เพื่อจำลอง server ตอบ error
/// - [gate]     : หน่วงการตอบ เพื่อดูสถานะ "กำลังบันทึก"
/// - [requests] : ข้อมูลที่ฟอร์มส่งมา (ใช้ตรวจว่า trim แล้ว)
class _FakeCreatePaymentService extends PaymentService {
  _FakeCreatePaymentService() : super(ApiService());

  Map<String, dynamic> response = {'payment_id': 42, 'status': 'Pending'};
  Object? error;
  Completer<void>? gate;
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
    await gate?.future;
    if (error != null) throw error!;
    return response;
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
// ปุ่มยืนยันส่งข้อมูล
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

  testWidgets('shows the order summary being paid', (tester) async {
    await _pump(tester, _FakeCreatePaymentService());

    expect(find.text('แจ้งการชำระเงิน'), findsOneWidget);
    expect(find.text('#17'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });

  testWidgets('empty form shows validation errors and sends nothing', (
    tester,
  ) async {
    final service = _FakeCreatePaymentService();
    await _pump(tester, service);

    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('กรุณาระบุช่องทางการชำระเงิน'), findsOneWidget);
    expect(find.text('กรุณากรอกเลขอ้างอิงการชำระเงิน'), findsOneWidget);
    expect(service.requests, isEmpty);
  });

  testWidgets('whitespace-only values are rejected', (tester) async {
    final service = _FakeCreatePaymentService();
    await _pump(tester, service);

    await tester.enterText(_methodField, '   ');
    await tester.enterText(_refField, '   ');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('กรุณาระบุช่องทางการชำระเงิน'), findsOneWidget);
    expect(find.text('กรุณากรอกเลขอ้างอิงการชำระเงิน'), findsOneWidget);
    expect(service.requests, isEmpty);
  });

  testWidgets('valid submit sends trimmed data and shows success', (
    tester,
  ) async {
    final service = _FakeCreatePaymentService();
    await _pump(tester, service);

    await tester.enterText(_methodField, '  PromptPay ');
    await tester.enterText(_refField, ' TX-777 ');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(service.requests.single, {
      'orderId': 17,
      'transactionRef': 'TX-777',
      'method': 'PromptPay',
    });
    expect(find.text('บันทึกข้อมูลสำเร็จ'), findsOneWidget);
    expect(find.text('บันทึกการชำระเงินสำเร็จ'), findsOneWidget);
    expect(find.text('#42'), findsOneWidget); // payment id
    expect(find.text('PromptPay'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('กลับไปหน้าแรก'), findsOneWidget);
  });

  testWidgets('button is disabled and relabelled while submitting', (
    tester,
  ) async {
    final service = _FakeCreatePaymentService()..gate = Completer<void>();
    await _pump(tester, service);

    await tester.enterText(_methodField, 'PromptPay');
    await tester.enterText(_refField, 'TX-1');
    await tester.tap(_submit);
    await tester.pump();

    expect(find.text('กำลังบันทึกข้อมูล...'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('กำลังบันทึกข้อมูล...'),
        matching: find.bySubtype<ElevatedButton>(),
      ),
    );
    expect(button.onPressed, isNull);

    service.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('บันทึกข้อมูลสำเร็จ'), findsOneWidget);
    expect(service.requests, hasLength(1));
  });

  // เมื่อ server ตอบ error: ฟอร์มต้องยังอยู่ (กดส่งซ้ำได้) และแสดงข้อความที่เหมาะสม
  group('server errors keep the form and show a message', () {
    // map: HTTP status code → ข้อความที่ผู้ใช้ควรเห็น
    final cases = <int, String>{
      400: 'กรุณาตรวจสอบเลขอ้างอิงและช่องทางชำระเงิน',
      401: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
      404: 'ไม่พบคำสั่งซื้อของคุณ',
      409:
          'คำสั่งซื้อนี้มีรายการชำระเงินแล้ว '
          'หรือไม่อยู่ในสถานะที่สามารถชำระเงินได้',
    };

    cases.forEach((status, message) {
      testWidgets('HTTP $status', (tester) async {
        final service = _FakeCreatePaymentService()
          ..error = ApiException(statusCode: status, message: 'ignored');
        await _pump(tester, service);

        await tester.enterText(_methodField, 'PromptPay');
        await tester.enterText(_refField, 'TX-1');
        await tester.tap(_submit);
        await tester.pumpAndSettle();

        expect(find.text(message), findsOneWidget);
        expect(find.text('บันทึกข้อมูลสำเร็จ'), findsNothing);
        expect(_submit, findsOneWidget); // can retry
      });
    });

    testWidgets('other status code shows server message', (tester) async {
      final service = _FakeCreatePaymentService()
        ..error = const ApiException(statusCode: 500, message: 'db down');
      await _pump(tester, service);

      await tester.enterText(_methodField, 'PromptPay');
      await tester.enterText(_refField, 'TX-1');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('db down'), findsOneWidget);
    });

    testWidgets('unexpected error shows generic message', (tester) async {
      final service = _FakeCreatePaymentService()..error = StateError('x');
      await _pump(tester, service);

      await tester.enterText(_methodField, 'PromptPay');
      await tester.enterText(_refField, 'TX-1');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่สามารถบันทึกข้อมูลการชำระเงินได้ กรุณาลองใหม่อีกครั้ง'),
        findsOneWidget,
      );
    });

    testWidgets('response without payment_id is treated as an error', (
      tester,
    ) async {
      final service = _FakeCreatePaymentService()..response = {'status': 'ok'};
      await _pump(tester, service);

      await tester.enterText(_methodField, 'PromptPay');
      await tester.enterText(_refField, 'TX-1');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่พบหมายเลขรายการชำระเงินจากเซิร์ฟเวอร์'),
        findsOneWidget,
      );
      expect(find.text('บันทึกข้อมูลสำเร็จ'), findsNothing);
    });

    testWidgets('error clears after a successful retry', (tester) async {
      final service = _FakeCreatePaymentService()
        ..error = const ApiException(statusCode: 404, message: 'x');
      await _pump(tester, service);

      await tester.enterText(_methodField, 'PromptPay');
      await tester.enterText(_refField, 'TX-1');
      await tester.tap(_submit);
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบคำสั่งซื้อของคุณ'), findsOneWidget);

      service.error = null;
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบคำสั่งซื้อของคุณ'), findsNothing);
      expect(find.text('บันทึกข้อมูลสำเร็จ'), findsOneWidget);
    });
  });
}
