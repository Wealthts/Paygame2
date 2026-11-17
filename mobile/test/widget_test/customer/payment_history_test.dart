import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/view/customer/payment_history_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "ประวัติการชำระเงิน" ของ customer ในแต่ละสถานะของหน้า
// (กำลังโหลด / ว่าง / มีข้อมูล / error)

PaymentModel _payment(
  int id,
  String status, {
  String ref = 'TX-1',
  double amount = 100,
}) => PaymentModel(
  paymentId: id,
  orderId: 200 + id,
  transactionRef: ref,
  method: 'PromptPay',
  amount: amount,
  status: status,
  gameName: 'Arena Test',
  packageName: '500 Diamonds',
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// PaymentService ปลอม
/// - [pending] : ถ้าตั้งไว้ การโหลดจะค้าง จนกว่าจะ complete (จำลองกำลังโหลด)
/// - [error]   : จำลองโหลดไม่สำเร็จ
/// - [calls]   : นับจำนวนครั้งที่โหลด (ใช้ตรวจว่า retry โหลดใหม่จริง)
class _FakeHistoryService extends PaymentService {
  _FakeHistoryService() : super(ApiService());

  List<PaymentModel> payments = [];
  Object? error;
  Completer<List<PaymentModel>>? pending;
  int calls = 0;

  @override
  Future<List<PaymentModel>> getMyPayments() {
    calls++;
    if (pending != null) return pending!.future;
    if (error != null) return Future.error(error!);
    return Future.value(List.of(payments));
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

  testWidgets('shows loading indicator while waiting', (tester) async {
    final service = _FakeHistoryService()..pending = Completer();
    await _pump(tester, service);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('กำลังโหลดประวัติการชำระเงิน...'), findsOneWidget);

    service.pending!.complete([_payment(1, 'Paid')]);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('empty history shows empty state', (tester) async {
    await _pump(tester, _FakeHistoryService());
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีประวัติการชำระเงิน'), findsOneWidget);
  });

  testWidgets('summary counts each status', (tester) async {
    final service = _FakeHistoryService()
      ..payments = [
        _payment(1, 'Pending', ref: 'A'),
        _payment(2, 'Pending', ref: 'B'),
        _payment(3, 'Paid', ref: 'C'),
        _payment(4, 'Cancelled', ref: 'D'),
      ];
    await _pump(tester, service);
    await tester.pumpAndSettle();

    // อ่านตัวเลขในช่องสรุป: หา Column ที่มี label นั้น แล้วเอา Text แรก (= ตัวเลข)
    String valueAbove(String label) {
      final column = find.ancestor(
        of: find.text(label),
        matching: find.byType(Column),
      );
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: column.first, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .toList();
      return texts.first!;
    }

    expect(valueAbove('ทั้งหมด'), '4');
    expect(valueAbove('รอตรวจสอบ'), '2');
    expect(valueAbove('ชำระแล้ว'), '1');
    expect(valueAbove('ยกเลิก'), '1');
  });

  testWidgets('lists every payment with reference and status label', (
    tester,
  ) async {
    final service = _FakeHistoryService()
      ..payments = [
        _payment(1, 'Pending', ref: 'TX-AAA'),
        _payment(2, 'Paid', ref: 'TX-BBB'),
      ];
    await _pump(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('TX-AAA'), findsOneWidget);
    expect(find.text('TX-BBB'), findsOneWidget);
    expect(find.text('รอตรวจสอบ'), findsWidgets);
    expect(find.text('ชำระแล้ว'), findsWidgets);
    expect(find.text('รายการชำระเงินทั้งหมด'), findsOneWidget);
  });

  testWidgets('error state offers retry which reloads data', (tester) async {
    final service = _FakeHistoryService()
      ..error = const ApiException(statusCode: 500, message: 'down');
    await _pump(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('ไม่สามารถโหลดประวัติการชำระเงินได้'), findsOneWidget);
    expect(service.calls, 1);

    service
      ..error = null
      ..payments = [_payment(9, 'Paid', ref: 'TX-RETRY')];
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(service.calls, 2);
    expect(find.text('TX-RETRY'), findsOneWidget);
    expect(find.text('ไม่สามารถโหลดประวัติการชำระเงินได้'), findsNothing);
  });
}
