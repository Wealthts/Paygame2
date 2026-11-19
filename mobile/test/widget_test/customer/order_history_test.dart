import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/order_history_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "รายการสั่งซื้อของฉัน" ฝั่ง customer
// และหน้าที่เปิดต่อจากหน้านี้ (ประวัติชำระเงิน, ใบเสร็จ, รายละเอียด order)

OrderModel _order(int id, String status, {String paymentStatus = 'Pending'}) =>
    OrderModel(
      orderId: id,
      userId: 10,
      packageId: 2,
      playerUid: '123456789',
      serverCode: '',
      gameName: 'Arena Test',
      packageName: '500 Diamonds',
      status: status,
      paymentStatus: paymentStatus,
      originalPrice: 159,
      discountAmount: 0,
      totalAmount: 159,
      couponDiscount: 0,
      feeAmount: 0,
      spentPoints: 0,
      createdAt: DateTime(2026, 1, 2, 12, 5),
    );

/// OrderService ปลอม
/// - [error]     : จำลองโหลดไม่สำเร็จ
/// - [cancelled] : id ของ order ที่ถูกยกเลิก
/// - [loads]     : จำนวนครั้งที่โหลดรายการ
class _FakeHistoryOrderService extends OrderService {
  _FakeHistoryOrderService() : super(ApiService());

  List<OrderModel> orders = [];
  Object? error;
  final cancelled = <int>[];
  int loads = 0;

  @override
  Future<List<OrderModel>> getMyOrders() async {
    loads++;
    if (error != null) throw error!;
    return List.of(orders);
  }

  @override
  Future<void> cancelMyOrder(int orderId) async {
    cancelled.add(orderId);
    orders = [
      for (final o in orders)
        o.orderId == orderId ? _order(orderId, 'Cancelled') : o,
    ];
  }
}

/// เปิดหน้าประวัติ order พร้อม service ปลอม
Future<void> _pumpHistory(
  WidgetTester tester,
  _FakeHistoryOrderService service,
) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<OrderService>.value(value: service),
        Provider<PaymentService>(create: (_) => FakePaymentService()),
        Provider<ReceiptService>(create: (_) => FakeReceiptService()),
      ],
      child: const MaterialApp(home: OrderHistoryView()),
    ),
  );
  await tester.pumpAndSettle();
}

/// เปิดหน้าประวัติที่มี order #17 แล้วกดเข้าไปหน้ารายละเอียด
Future<_FakeHistoryOrderService> _openDetails(
  WidgetTester tester, {
  String paymentStatus = 'Pending',
}) async {
  final service = _FakeHistoryOrderService()
    ..orders = [_order(17, 'Pending', paymentStatus: paymentStatus)];
  await _pumpHistory(tester, service);

  await tester.tap(find.text('Order #17'));
  await tester.pumpAndSettle();
  return service;
}

Widget _app() {
  return MultiProvider(
    providers: [
      Provider<OrderService>(create: (_) => FakeOrderService()),
      Provider<PaymentService>(create: (_) => FakePaymentService()),
      Provider<ReceiptService>(create: (_) => FakeReceiptService()),
    ],
    child: const MaterialApp(home: OrderHistoryView()),
  );
}

void main() {
  // ---------- การนำทางจากหน้าประวัติ order ----------
  group('navigation from order history', () {
    testWidgets(
      'payment and receipt history actions belong to customer homepage',
      (tester) async {
        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        expect(find.byTooltip('ประวัติการชำระเงิน'), findsNothing);
        expect(find.byTooltip('ใบเสร็จของฉัน'), findsNothing);
      },
    );

    testWidgets('tapping an order opens details and back returns to history', (
      tester,
    ) async {
      await _openDetails(tester);

      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('รายการสั่งซื้อของฉัน'), findsOneWidget);
      expect(find.text('Order #17'), findsOneWidget);
    });
  });

  // ---------- หน้าประวัติ order ----------
  group('order history', () {
    testWidgets('empty history shows empty state', (tester) async {
      await _pumpHistory(tester, _FakeHistoryOrderService());

      expect(find.text('ยังไม่มีคำสั่งซื้อ'), findsOneWidget);
    });

    testWidgets('shows each order with game and package', (tester) async {
      final service = _FakeHistoryOrderService()
        ..orders = [_order(1, 'Pending'), _order(2, 'Completed')];
      await _pumpHistory(tester, service);

      expect(find.text('Order #1'), findsOneWidget);
      expect(find.text('Order #2'), findsOneWidget);
      expect(find.text('Arena Test'), findsNWidgets(2));
      expect(find.text('500 Diamonds'), findsNWidgets(2));
    });

    testWidgets('shows error and can retry', (tester) async {
      final service = _FakeHistoryOrderService()
        ..error = const ApiException(statusCode: 500, message: 'down');
      await _pumpHistory(tester, service);
      expect(find.text('ไม่สามารถโหลดประวัติคำสั่งซื้อได้'), findsOneWidget);

      service
        ..error = null
        ..orders = [_order(5, 'Completed')];
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(find.text('Order #5'), findsOneWidget);
    });
  });

  // ---------- หน้ารายละเอียด + ยกเลิก order ----------
  group('order details', () {
    testWidgets('tapping an order opens its details', (tester) async {
      await _openDetails(tester);

      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget); // Player UID
    });

    testWidgets('cancel button is hidden once the order is paid', (
      tester,
    ) async {
      await _openDetails(tester, paymentStatus: 'Paid');

      expect(find.text('ยกเลิกคำสั่งซื้อ'), findsNothing);
    });

    testWidgets('cancelling returns to history and reloads the list', (
      tester,
    ) async {
      final service = await _openDetails(tester);

      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(service.cancelled, [17]);
      expect(service.loads, 2); // โหลดรายการใหม่หลังยกเลิก
      expect(find.text('Order #17'), findsOneWidget);
    });
  });
}
