import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/view/customer/order_details_view.dart';
import 'package:mobile/view/customer/order_history_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "รายการสั่งซื้อของฉัน" (OrderHistoryView) ฝั่ง customer
// และหน้าที่เปิดต่อจากหน้านี้ ได้แก่ ประวัติการชำระเงิน, ใบเสร็จ และรายละเอียด order
// ครอบคลุม: สถานะของหน้า (โหลด/ว่าง/มีข้อมูล/error), การนำทาง,
// ข้อมูลในหน้ารายละเอียด และขั้นตอนยกเลิก order

/// สร้าง order สำหรับเทสต์ (override เฉพาะ field ที่สนใจ)
/// ถ้าไม่ระบุ [original] จะใช้ total + discount
OrderModel _order(
  int id,
  String status, {
  String? paymentStatus,
  String game = 'Arena Test',
  String serverCode = '',
  String? couponCode,
  double? original,
  double discount = 0,
  double couponDiscount = 0,
  double total = 159,
  int spentPoints = 0,
}) => OrderModel(
  orderId: id,
  userId: 10,
  packageId: 2,
  playerUid: '123456789',
  serverCode: serverCode,
  gameName: game,
  packageName: '500 Diamonds',
  status: status,
  paymentStatus: paymentStatus ?? 'Pending',
  originalPrice: original ?? total + discount,
  discountAmount: discount,
  totalAmount: total,
  couponDiscount: couponDiscount,
  feeAmount: 0,
  spentPoints: spentPoints,
  couponCode: couponCode,
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// OrderService ปลอม
/// - [orders]      : รายการที่ getMyOrders คืน
/// - [pending]     : ถ้าตั้งไว้ การโหลดจะค้างจนกว่าจะ complete (จำลองกำลังโหลด)
/// - [error]       : จำลองโหลดไม่สำเร็จ
/// - [cancelError] : จำลองยกเลิกไม่สำเร็จ
/// - [cancelled]   : id ของ order ที่ถูกยกเลิก
/// - [loads]       : นับจำนวนครั้งที่โหลด (ใช้ตรวจว่า retry/refresh โหลดใหม่จริง)
class _FakeHistoryOrderService extends OrderService {
  _FakeHistoryOrderService() : super(ApiService());

  List<OrderModel> orders = [];
  Object? error;
  Object? cancelError;
  Completer<List<OrderModel>>? pending;
  final cancelled = <int>[];
  int loads = 0;

  @override
  Future<List<OrderModel>> getMyOrders() {
    loads++;
    if (pending != null) return pending!.future;
    if (error != null) return Future.error(error!);
    return Future.value(List.of(orders));
  }

  @override
  Future<void> cancelMyOrder(int orderId) async {
    if (cancelError != null) throw cancelError!;
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
}

/// เปิดหน้ารายละเอียดจากปุ่มบนหน้าเริ่มต้น และเก็บค่าที่หน้านั้น pop กลับมา
/// (ใช้ตรวจว่ายกเลิกสำเร็จแล้ว pop(true))
Future<void> _pumpDetails(
  WidgetTester tester,
  OrderModel order,
  _FakeHistoryOrderService service, {
  void Function(bool?)? onResult,
}) async {
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // ล้างหน้าจอก่อน เผื่อเทสต์เรียกฟังก์ชันนี้ซ้ำหลายรอบในเทสต์เดียว
  await tester.pumpWidget(const SizedBox());

  await tester.pumpWidget(
    Provider<OrderService>.value(
      value: service,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CustomerOrderDetailsView(order: order),
                    ),
                  );
                  onResult?.call(result);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
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
  // ---------- การนำทางจากหน้าประวัติ order (เทสต์เดิม) ----------
  group('navigation from order history', () {
    testWidgets('user can open payment history from order history', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('ประวัติการชำระเงิน'));
      await tester.pumpAndSettle();

      expect(find.text('TX-TEST-001'), findsOneWidget);
    });

    testWidgets('user can open receipt history from order history', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('ใบเสร็จของฉัน'));
      await tester.pumpAndSettle();

      expect(find.text('PG-TEST-0005'), findsOneWidget);
    });
  });

  // ---------- สถานะของหน้าประวัติ order ----------
  group('order history states', () {
    testWidgets('shows loading indicator while waiting', (tester) async {
      final service = _FakeHistoryOrderService()..pending = Completer();
      await _pumpHistory(tester, service);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('กำลังโหลดประวัติคำสั่งซื้อ...'), findsOneWidget);

      service.pending!.complete([_order(1, 'Pending')]);
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('empty history shows empty state', (tester) async {
      await _pumpHistory(tester, _FakeHistoryOrderService());
      await tester.pumpAndSettle();

      expect(find.text('ยังไม่มีคำสั่งซื้อ'), findsOneWidget);
      expect(find.text('Order #1'), findsNothing);
    });

    testWidgets('renders each order with game, package and total', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService()
        ..orders = [
          _order(1, 'Pending', total: 159),
          _order(2, 'Completed', total: 80),
        ];
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('รายการสั่งซื้อของฉัน'), findsOneWidget);
      expect(find.text('Order #1'), findsOneWidget);
      expect(find.text('Order #2'), findsOneWidget);
      expect(find.text('Arena Test'), findsNWidgets(2));
      expect(find.text('500 Diamonds'), findsNWidgets(2));
      expect(find.text('฿159.00'), findsWidgets);
      expect(find.text('฿80.00'), findsWidgets);
    });

    testWidgets('maps every status to its Thai label', (tester) async {
      final service = _FakeHistoryOrderService()
        ..orders = [
          _order(1, 'Pending'),
          _order(2, 'Processing'),
          _order(3, 'Completed'),
          _order(4, 'Cancelled'),
        ];
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('รอดำเนินการ'), findsWidgets);
      expect(find.text('กำลังดำเนินการ'), findsWidgets);
      expect(find.text('สำเร็จ'), findsWidgets);
      expect(find.text('ยกเลิก'), findsWidgets);
    });

    testWidgets('discount is shown only when the order has one', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService()
        ..orders = [_order(1, 'Pending', total: 90, discount: 10)];
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('ส่วนลดรวม'), findsOneWidget);
      expect(find.text('-฿10.00'), findsOneWidget);
    });

    testWidgets('discount row is hidden when there is no discount', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService()
        ..orders = [_order(2, 'Pending')];
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('ส่วนลดรวม'), findsNothing);
    });

    testWidgets('error state offers retry which reloads data', (tester) async {
      final service = _FakeHistoryOrderService()
        ..error = const ApiException(statusCode: 500, message: 'down');
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();

      expect(find.text('ไม่สามารถโหลดประวัติคำสั่งซื้อได้'), findsOneWidget);
      expect(service.loads, 1);

      service
        ..error = null
        ..orders = [_order(5, 'Completed')];
      await tester.tap(find.text('ลองอีกครั้ง'));
      await tester.pumpAndSettle();

      expect(service.loads, 2);
      expect(find.text('Order #5'), findsOneWidget);
    });
  });

  // ---------- ข้อมูลในหน้ารายละเอียด order ----------
  group('order details content', () {
    testWidgets('shows order, player and price information', (tester) async {
      await _pumpDetails(
        tester,
        _order(
          17,
          'Pending',
          serverCode: 'TH-01',
          couponCode: 'SAVE10',
          original: 159,
          discount: 20,
          couponDiscount: 10,
          total: 139,
          spentPoints: 100,
        ),
        _FakeHistoryOrderService(),
      );

      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
      expect(find.text('Arena Test'), findsOneWidget);
      expect(find.text('500 Diamonds'), findsOneWidget);
      expect(find.text('123456789'), findsOneWidget);
      expect(find.text('TH-01'), findsOneWidget);
      expect(find.text('฿159.00'), findsOneWidget);
      expect(find.text('- ฿20.00'), findsOneWidget); // ส่วนลดรวม
      expect(find.text('- ฿10.00'), findsOneWidget); // ส่วนลดคูปอง
      expect(find.text('SAVE10'), findsOneWidget);
      expect(find.text('100 แต้ม'), findsOneWidget);
      expect(find.text('฿139.00'), findsOneWidget); // ยอดชำระทั้งหมด
      expect(find.text('02/01/2026 12:05'), findsOneWidget);
    });

    testWidgets(
      'Server ID row is hidden and coupon code is dashed when empty',
      (tester) async {
        await _pumpDetails(
          tester,
          _order(17, 'Pending'),
          _FakeHistoryOrderService(),
        );

        expect(find.text('Server ID'), findsNothing);
        expect(find.text('โค้ดคูปอง'), findsOneWidget);
        expect(find.text('-'), findsNWidgets(2)); // โค้ดคูปอง + วันที่เสร็จสิ้น
      },
    );

    testWidgets('maps every order status to its Thai label', (tester) async {
      const labels = {
        'Pending': 'รอดำเนินการ',
        'Processing': 'กำลังดำเนินการ',
        'Completed': 'สำเร็จ',
        'Cancelled': 'ยกเลิก',
      };

      for (final entry in labels.entries) {
        await _pumpDetails(
          tester,
          _order(17, entry.key),
          _FakeHistoryOrderService(),
        );
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      }
    });

    testWidgets('maps every payment status to its Thai label', (tester) async {
      const labels = {
        'Pending': 'รอชำระเงิน',
        'Paid': 'ชำระเงินแล้ว',
        'Cancelled': 'การชำระเงินถูกยกเลิก',
        'None':
            'ยังไม่มีรายการชำระเงิน', // สถานะที่ระบบไม่รู้จัก = ยังไม่มีรายการ
      };

      for (final entry in labels.entries) {
        await _pumpDetails(
          tester,
          _order(17, 'Pending', paymentStatus: entry.key),
          _FakeHistoryOrderService(),
        );
        expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      }
    });
  });

  // ---------- เงื่อนไขของปุ่มยกเลิก ----------
  group('cancel button visibility', () {
    testWidgets('shown for Pending order that is not paid', (tester) async {
      await _pumpDetails(
        tester,
        _order(17, 'Pending'),
        _FakeHistoryOrderService(),
      );
      expect(find.text('ยกเลิกคำสั่งซื้อ'), findsOneWidget);
    });

    testWidgets('hidden once payment is Paid', (tester) async {
      await _pumpDetails(
        tester,
        _order(17, 'Pending', paymentStatus: 'Paid'),
        _FakeHistoryOrderService(),
      );
      expect(find.text('ยกเลิกคำสั่งซื้อ'), findsNothing);
    });

    testWidgets('hidden for non-Pending orders', (tester) async {
      for (final status in ['Processing', 'Completed', 'Cancelled']) {
        await _pumpDetails(
          tester,
          _order(17, status),
          _FakeHistoryOrderService(),
        );
        expect(find.text('ยกเลิกคำสั่งซื้อ'), findsNothing, reason: status);
      }
    });
  });

  // ---------- ขั้นตอนยกเลิก ----------
  group('cancel flow', () {
    testWidgets('confirm cancels, shows snackbar and pops with true', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService();
      bool? result;
      await _pumpDetails(
        tester,
        _order(17, 'Pending'),
        service,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();
      expect(find.text('ยืนยันการยกเลิกคำสั่งซื้อ'), findsOneWidget);

      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(service.cancelled, [17]);
      expect(find.text('ยกเลิกคำสั่งซื้อเรียบร้อยแล้ว'), findsOneWidget);
      expect(result, isTrue);
      expect(find.text('คำสั่งซื้อ #17'), findsNothing); // กลับหน้าก่อนหน้าแล้ว
    });

    testWidgets('choosing back keeps the page and does not cancel', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService();
      await _pumpDetails(tester, _order(17, 'Pending'), service);

      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับ'));
      await tester.pumpAndSettle();

      expect(service.cancelled, isEmpty);
      expect(find.text('ยืนยันการยกเลิกคำสั่งซื้อ'), findsNothing);
      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
    });

    testWidgets('server error shows snackbar and stays on the page', (
      tester,
    ) async {
      final service = _FakeHistoryOrderService()
        ..cancelError = const ApiException(
          statusCode: 409,
          message: 'already processing',
        );
      bool? result = false;
      await _pumpDetails(
        tester,
        _order(17, 'Pending'),
        service,
        onResult: (value) => result = value,
      );

      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่สามารถยกเลิกคำสั่งซื้อได้: already processing'),
        findsOneWidget,
      );
      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
      expect(result, isFalse); // ยังไม่ pop
    });
  });

  // ---------- จากหน้าประวัติ → รายละเอียด → ยกเลิก → ประวัติรีเฟรช ----------
  group('history → details → cancel', () {
    Future<_FakeHistoryOrderService> pumpWithOrder(WidgetTester tester) async {
      final service = _FakeHistoryOrderService()
        ..orders = [_order(17, 'Pending')];
      await _pumpHistory(tester, service);
      await tester.pumpAndSettle();
      return service;
    }

    testWidgets('tapping an order card opens its details', (tester) async {
      await pumpWithOrder(tester);

      await tester.tap(find.text('Order #17'));
      await tester.pumpAndSettle();

      expect(find.text('คำสั่งซื้อ #17'), findsOneWidget);
      expect(find.text('ข้อมูลคำสั่งซื้อ'), findsOneWidget);
    });

    testWidgets('cancelling returns to history and reloads the list', (
      tester,
    ) async {
      final service = await pumpWithOrder(tester);
      expect(service.loads, 1);

      await tester.tap(find.text('Order #17'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ยืนยันยกเลิก'));
      await tester.pumpAndSettle();

      expect(service.loads, 2); // โหลดซ้ำหลังยกเลิก
      expect(find.text('Order #17'), findsOneWidget);
      expect(find.text('ยกเลิก'), findsWidgets); // สถานะเปลี่ยนเป็นยกเลิก
    });

    testWidgets('backing out without cancelling does not reload', (
      tester,
    ) async {
      final service = await pumpWithOrder(tester);

      await tester.tap(find.text('Order #17'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(service.loads, 1);
    });
  });
}
