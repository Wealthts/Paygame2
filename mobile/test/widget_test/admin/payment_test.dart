import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/admin/payment_view.dart';

import '../../support/theme_widget_test_helper.dart';

// Widget test หน้า Payments Management ของ admin
// ใช้ service ปลอมที่เก็บข้อมูลไว้ใน memory และบันทึกว่าถูกเรียกอะไรบ้างใน [calls]

PaymentModel _payment(
  int id,
  String status, {
  String ref = 'TX-1',
  String method = 'PromptPay',
}) => PaymentModel(
  paymentId: id,
  orderId: 100 + id,
  transactionRef: ref, // เลขอ้างอิงการโอน
  method: method,
  amount: 159,
  status: status,
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// PaymentService ปลอม
/// - [calls] : เมธอดที่ถูกเรียก เช่น 'paid:1'
class _FakeAdminPaymentService extends PaymentService {
  _FakeAdminPaymentService(this.payments) : super(ApiService());

  List<PaymentModel> payments;
  final calls = <String>[];

  @override
  Future<List<PaymentModel>> getAllPayments() async {
    calls.add('getAll');
    return List.of(payments);
  }

  @override
  Future<void> markAsPaid(int paymentId) async {
    calls.add('paid:$paymentId');
    payments = [
      for (final p in payments)
        p.paymentId == paymentId ? _payment(paymentId, 'Paid') : p,
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

/// เปิดหน้า PaymentView พร้อม service ปลอม (จอสูงเพื่อให้การ์ดทุกใบกดได้)
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

/// หาข้อความเฉพาะในการ์ด payment (กันชนกับ filter chip ที่มีคำเดียวกัน)
Finder _inCard(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  // เทสต์เดิม: ตรวจ theme ของแอป
  testPayGameThemeContract('Admin payment management');

  testWidgets('shows payment card with order, method and reference', (
    tester,
  ) async {
    await _pump(
      tester,
      _FakeAdminPaymentService([_payment(1, 'Pending', ref: 'TX-ABC')]),
    );

    expect(find.text('Payments Management'), findsOneWidget);
    expect(find.text('Payment #1'), findsOneWidget);
    expect(find.text('Order #101'), findsOneWidget);
    expect(find.text('ช่องทาง: PromptPay'), findsOneWidget);
    expect(find.text('เลขอ้างอิง: TX-ABC'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no payments', (tester) async {
    await _pump(tester, _FakeAdminPaymentService([]));

    expect(find.text('ยังไม่มีรายการชำระเงิน'), findsOneWidget);
  });

  testWidgets('only Pending payments can be confirmed', (tester) async {
    await _pump(
      tester,
      _FakeAdminPaymentService([_payment(1, 'Paid'), _payment(2, 'Cancelled')]),
    );

    expect(find.text('ยืนยันชำระเงิน'), findsNothing);
  });

  // ช่องค้นหา + chip กรองสถานะ
  group('filtering', () {
    final payments = [
      _payment(1, 'Pending', ref: 'TX-AAA'),
      _payment(2, 'Paid', ref: 'TX-BBB'),
      _payment(3, 'Cancelled', ref: 'TX-CCC'),
    ];

    testWidgets('status chip filters the list', (tester) async {
      await _pump(tester, _FakeAdminPaymentService(payments));

      await tester.tap(find.widgetWithText(ChoiceChip, 'ชำระแล้ว'));
      await tester.pumpAndSettle();

      expect(find.text('Payment #2'), findsOneWidget);
      expect(find.text('Payment #1'), findsNothing);
    });

    testWidgets('search by reference', (tester) async {
      await _pump(tester, _FakeAdminPaymentService(payments));

      await tester.enterText(find.byType(TextField), 'tx-ccc');
      await tester.pumpAndSettle();

      expect(find.text('Payment #3'), findsOneWidget);
      expect(find.text('Payment #1'), findsNothing);
    });
  });

  // กดปุ่ม → dialog ยืนยัน → เรียก service → โหลดรายการใหม่
  group('actions', () {
    testWidgets('mark a payment as paid', (tester) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(find.text('ยืนยันชำระเงิน'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'paid:1', 'getAll']);
      expect(_inCard('ชำระแล้ว'), findsOneWidget);
    });

    testWidgets('cancel a payment', (tester) async {
      final service = _FakeAdminPaymentService([_payment(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(_inCard('ยกเลิก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'cancel:1', 'getAll']);
    });
  });
}
