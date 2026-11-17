import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/admin/payment_view.dart';

import '../../support/theme_widget_test_helper.dart';

// Widget test หน้า Payments Management ของ admin
// ใช้ service ปลอมที่จำข้อมูลใน memory และบันทึก [calls] ไว้ตรวจสอบ

PaymentModel _payment(
  int id,
  String status, {
  String ref = 'TX-1',
  String method = 'PromptPay',
  double amount = 159,
  DateTime? paidAt,
}) => PaymentModel(
  paymentId: id,
  orderId: 100 + id,
  transactionRef: ref,
  method: method,
  amount: amount,
  status: status,
  createdAt: DateTime(2026, 1, 2, 12, 5),
  paidAt: paidAt,
);

/// PaymentService ปลอมสำหรับ admin
/// - [loadError] : ตั้งไว้เพื่อจำลองโหลดข้อมูลไม่สำเร็จ
/// - [calls]     : ลำดับเมธอดที่ถูกเรียก เช่น 'paid:1'
class _FakeAdminPaymentService extends PaymentService {
  _FakeAdminPaymentService(this.payments) : super(ApiService());

  List<PaymentModel> payments;
  Object? loadError;
  final calls = <String>[];

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    calls.add('getAll');
    if (loadError != null) throw loadError!;
    return List.of(payments);
  }

  @override
  Future<void> markAsPaid(int paymentId) async {
    calls.add('paid:$paymentId');
    payments = [
      for (final p in payments)
        p.paymentId == paymentId
            ? _payment(paymentId, 'Paid', paidAt: DateTime(2026, 1, 3, 9))
            : p,
    ];
  }

  @override
  Future<void> cancelPayment(int paymentId) async {
    calls.add('cancel:$paymentId');
    payments = [
      for (final p in payments)
        p.paymentId == paymentId ? _payment(paymentId, 'Cancelled') : p,
    ];
  }
}

/// เปิดหน้า PaymentView พร้อม service ปลอม
/// ขยายหน้าจอเทสต์ให้สูง เพื่อให้การ์ดทุกใบอยู่ในจอและกดได้
Future<void> _pump(
  WidgetTester tester,
  _FakeAdminPaymentService service,
) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<PaymentService>.value(
      value: service,
      child: const MaterialApp(home: PaymentView()),
    ),
  );
  await tester.pumpAndSettle();
}

/// หาข้อความ "ภายในการ์ด payment" เท่านั้น (กันชนกับ filter chip ด้านบน)
Finder _inCard(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  // เทสต์เดิม: ตรวจ theme ของแอป
  testPayGameThemeContract('Admin payment management');

  testWidgets('shows loading indicator then payments', (tester) async {
    final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<PaymentService>.value(
        value: service,
        child: const MaterialApp(home: PaymentView()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Payments Management'), findsOneWidget);
    expect(find.text('Payment #1'), findsOneWidget);
    expect(find.text('แสดง 1 จาก 1 รายการ'), findsOneWidget);
  });

  testWidgets('card shows order, method, reference and amount', (tester) async {
    await _pump(
      tester,
      _FakeAdminPaymentService([
        _payment(1, 'Pending', ref: 'TX-ABC', amount: 250.5),
      ]),
    );

    expect(find.text('Order #101'), findsOneWidget);
    expect(find.text('ช่องทาง: PromptPay'), findsOneWidget);
    expect(find.text('เลขอ้างอิง: TX-ABC'), findsOneWidget);
    expect(find.text('฿250.50'), findsOneWidget);
    expect(find.text('วันที่สร้าง: 02/01/2026 12:05'), findsOneWidget);
    expect(find.textContaining('วันที่ชำระ'), findsNothing);
  });

  testWidgets('paid payment shows paid date', (tester) async {
    await _pump(
      tester,
      _FakeAdminPaymentService([
        _payment(1, 'Paid', paidAt: DateTime(2026, 1, 3, 9, 30)),
      ]),
    );

    expect(find.text('วันที่ชำระ: 03/01/2026 09:30'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no payments', (tester) async {
    await _pump(tester, _FakeAdminPaymentService([]));

    expect(find.text('ยังไม่มีรายการชำระเงิน'), findsOneWidget);
  });

  testWidgets('shows error view and retries successfully', (tester) async {
    final service = _FakeAdminPaymentService([_payment(1, 'Pending')])
      ..loadError = const ApiException(statusCode: 500, message: 'server down');
    await _pump(tester, service);

    expect(find.text('server down'), findsOneWidget);

    service.loadError = null;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('Payment #1'), findsOneWidget);
  });

  // กฎของปุ่ม: เฉพาะ Pending ที่ยืนยัน/ยกเลิกได้
  group('action buttons depend on status', () {
    testWidgets('Pending shows confirm and cancel', (tester) async {
      await _pump(tester, _FakeAdminPaymentService([_payment(1, 'Pending')]));

      expect(find.text('ยืนยันชำระเงิน'), findsOneWidget);
      expect(_inCard('ยกเลิก'), findsOneWidget);
    });

    testWidgets('Paid and Cancelled only show details', (tester) async {
      await _pump(
        tester,
        _FakeAdminPaymentService([
          _payment(1, 'Paid'),
          _payment(2, 'Cancelled'),
        ]),
      );

      expect(find.text('ยืนยันชำระเงิน'), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
      expect(find.text('รายละเอียด'), findsNWidgets(2));
    });
  });

  // ช่องค้นหา + chip กรองสถานะ
  group('filtering', () {
    final payments = [
      _payment(1, 'Pending', ref: 'TX-AAA'),
      _payment(2, 'Paid', ref: 'TX-BBB', method: 'Bank Transfer'),
      _payment(3, 'Cancelled', ref: 'TX-CCC'),
    ];

    testWidgets('status chip filters list', (tester) async {
      await _pump(tester, _FakeAdminPaymentService(payments));

      await tester.tap(find.widgetWithText(ChoiceChip, 'ชำระแล้ว'));
      await tester.pumpAndSettle();

      expect(find.text('Payment #2'), findsOneWidget);
      expect(find.text('Payment #1'), findsNothing);
      expect(find.text('แสดง 1 จาก 3 รายการ'), findsOneWidget);
    });

    testWidgets('search matches reference and method', (tester) async {
      await _pump(tester, _FakeAdminPaymentService(payments));

      await tester.enterText(find.byType(TextField), 'tx-ccc');
      await tester.pumpAndSettle();
      expect(find.text('Payment #3'), findsOneWidget);
      expect(find.text('Payment #1'), findsNothing);

      await tester.enterText(find.byType(TextField), 'bank');
      await tester.pumpAndSettle();
      expect(find.text('Payment #2'), findsOneWidget);
    });

    testWidgets('no match shows message and clear resets', (tester) async {
      await _pump(tester, _FakeAdminPaymentService(payments));

      await tester.enterText(find.byType(TextField), 'nothing-here');
      await tester.pumpAndSettle();
      expect(find.text('ไม่พบรายการชำระเงินที่ตรงกับการค้นหา'), findsOneWidget);

      await tester.tap(find.text('ล้างคำค้นหาและตัวกรอง'));
      await tester.pumpAndSettle();
      expect(find.text('แสดง 3 จาก 3 รายการ'), findsOneWidget);
    });
  });

  // กดปุ่ม → มี dialog ยืนยัน → เรียก service → รายการรีเฟรช
  group('actions', () {
    testWidgets('mark as paid: confirm updates payment', (tester) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(find.text('ยืนยันชำระเงิน'));
      await tester.pumpAndSettle();
      expect(
        find.text('ยืนยันว่า Payment #1 ได้รับเงินแล้วใช่หรือไม่?'),
        findsOneWidget,
      );

      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'paid:1', 'getAll']);
      expect(find.text('ยืนยันชำระเงิน'), findsNothing);
      expect(_inCard('ชำระแล้ว'), findsOneWidget);
    });

    testWidgets('mark as paid: back does nothing', (tester) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(find.text('ยืนยันชำระเงิน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับ'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll']);
    });

    testWidgets('cancel payment: confirm updates payment', (tester) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(_inCard('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('ต้องการยกเลิก Payment #1 ใช่หรือไม่?'), findsOneWidget);

      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'cancel:1', 'getAll']);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('failed action keeps list and shows error banner', (
      tester,
    ) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);
      service.loadError = const ApiException(
        statusCode: 409,
        message: 'already processed',
      );

      await tester.tap(find.text('ยืนยันชำระเงิน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(find.text('already processed'), findsOneWidget);
      expect(find.text('Payment #1'), findsOneWidget);
    });

    testWidgets('details dialog shows full payment information', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeAdminPaymentService([_payment(4, 'Pending', ref: 'TX-DETAIL')]),
      );

      await tester.tap(find.text('รายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('Transaction Ref'), findsOneWidget);
      expect(find.text('TX-DETAIL'), findsOneWidget);
      expect(find.text('Paid At'), findsOneWidget);

      await tester.tap(find.text('ปิด'));
      await tester.pumpAndSettle();
      expect(find.text('Transaction Ref'), findsNothing);
    });
  });
}
