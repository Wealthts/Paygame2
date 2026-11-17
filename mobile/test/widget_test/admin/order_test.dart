import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/view/admin/order_view.dart';

import '../../support/theme_widget_test_helper.dart';

// Widget test หน้า Orders Management ของ admin
// ใช้ service ปลอมที่จำข้อมูลใน memory และบันทึก [calls] ไว้ตรวจสอบ
OrderModel _order(
  int id,
  String status, {
  String game = 'Arena Test',
  String package = '500 Diamonds',
  String uid = '111',
  String? displayName = 'Alice',
}) => OrderModel(
  orderId: id,
  userId: 1,
  packageId: 1,
  playerUid: uid,
  serverCode: '',
  gameName: game,
  packageName: package,
  status: status,
  paymentStatus: 'Pending',
  originalPrice: 159,
  discountAmount: 0,
  totalAmount: 159,
  couponDiscount: 0,
  feeAmount: 0,
  spentPoints: 0,
  username: 'alice',
  displayName: displayName,
  createdAt: DateTime(2026, 1, 2, 12, 5),
);

/// OrderService ปลอมสำหรับ admin
/// - [loadError] : ตั้งไว้เพื่อจำลองโหลดข้อมูลไม่สำเร็จ
/// - [calls]     : ลำดับเมธอดที่ถูกเรียก เช่น 'cancel:1'
class _FakeAdminOrderService extends OrderService {
  _FakeAdminOrderService(this.orders) : super(ApiService());

  List<OrderModel> orders;
  Object? loadError;
  final calls = <String>[];

  @override
  Future<List<OrderModel>> getAllOrders() async {
    calls.add('getAll');
    if (loadError != null) throw loadError!;
    return List.of(orders);
  }

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    calls.add('update:$orderId:$status');
    orders = [
      for (final o in orders)
        o.orderId == orderId ? _order(orderId, status) : o,
    ];
  }

  @override
  Future<void> cancelOrder(int orderId) async {
    calls.add('cancel:$orderId');
    orders = [
      for (final o in orders)
        o.orderId == orderId ? _order(orderId, 'Cancelled') : o,
    ];
  }
}

/// เปิดหน้า OrderView พร้อม service ปลอม
/// ขยายหน้าจอเทสต์ให้สูง เพื่อให้การ์ดทุกใบอยู่ในจอและกดได้
Future<void> _pump(WidgetTester tester, _FakeAdminOrderService service) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<OrderService>.value(
      value: service,
      child: const MaterialApp(home: OrderView()),
    ),
  );
  await tester.pumpAndSettle();
}

/// หาข้อความ "ภายในการ์ด order" เท่านั้น
/// (กันชนกับข้อความชื่อเดียวกันของ filter chip ด้านบน เช่น 'ยกเลิก', 'เสร็จสิ้น')
Finder _inCard(String text) =>
    find.descendant(of: find.byType(Card), matching: find.text(text));

void main() {
  // เทสต์เดิม: ตรวจ theme ของแอป
  testPayGameThemeContract('Admin order management');

  testWidgets('shows loading indicator then the order list', (tester) async {
    final service = _FakeAdminOrderService([_order(1, 'Pending')]);
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      Provider<OrderService>.value(
        value: service,
        child: const MaterialApp(home: OrderView()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Orders Management'), findsOneWidget);
    expect(find.text('Order #1'), findsOneWidget);
    expect(find.text('แสดง 1 จาก 1 รายการ'), findsOneWidget);
  });

  testWidgets('card shows customer, package, uid and total', (tester) async {
    await _pump(tester, _FakeAdminOrderService([_order(7, 'Pending')]));

    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('แพ็กเกจ: 500 Diamonds'), findsOneWidget);
    expect(find.text('ลูกค้า: Alice'), findsOneWidget);
    expect(find.text('UID: 111'), findsOneWidget);
    expect(find.text('฿159.00'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no orders', (tester) async {
    await _pump(tester, _FakeAdminOrderService([]));

    expect(find.text('ยังไม่มีคำสั่งซื้อ'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('shows error view and retries successfully', (tester) async {
    final service = _FakeAdminOrderService([_order(1, 'Pending')])
      ..loadError = const ApiException(statusCode: 500, message: 'server down');
    await _pump(tester, service);

    expect(find.text('server down'), findsOneWidget);

    service.loadError = null;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('server down'), findsNothing);
    expect(find.text('Order #1'), findsOneWidget);
  });

  testWidgets('refresh button reloads orders', (tester) async {
    final service = _FakeAdminOrderService([_order(1, 'Pending')]);
    await _pump(tester, service);

    await tester.tap(find.byTooltip('Refresh'));
    await tester.pumpAndSettle();

    expect(service.calls.where((c) => c == 'getAll'), hasLength(2));
  });

  // กฎของปุ่ม: Pending ยกเลิกได้, Processing ปิดงานได้, สถานะอื่นดูรายละเอียดอย่างเดียว
  group('action buttons depend on status', () {
    testWidgets('Pending can be cancelled but not completed', (tester) async {
      await _pump(tester, _FakeAdminOrderService([_order(1, 'Pending')]));

      expect(_inCard('ยกเลิก'), findsOneWidget);
      expect(_inCard('เสร็จสิ้น'), findsNothing);
    });

    testWidgets('Processing can be completed but not cancelled', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminOrderService([_order(1, 'Processing')]));

      expect(_inCard('เสร็จสิ้น'), findsOneWidget);
      expect(_inCard('ยกเลิก'), findsNothing);
    });

    testWidgets('Completed and Cancelled have only the details button', (
      tester,
    ) async {
      await _pump(
        tester,
        _FakeAdminOrderService([
          _order(1, 'Completed'),
          _order(2, 'Cancelled'),
        ]),
      );

      expect(find.text('รายละเอียด'), findsNWidgets(2));
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });
  });

  // ช่องค้นหา + chip กรองสถานะ
  group('filtering', () {
    final orders = [
      _order(1, 'Pending', game: 'Arena Test'),
      _order(2, 'Processing', game: 'Racing Pro', uid: '222'),
      _order(
        3,
        'Completed',
        game: 'Arena Test',
        uid: '333',
        displayName: 'Bob',
      ),
    ];

    testWidgets('status chip filters the list', (tester) async {
      await _pump(tester, _FakeAdminOrderService(orders));

      await tester.tap(find.widgetWithText(ChoiceChip, 'กำลังดำเนินการ'));
      await tester.pumpAndSettle();

      expect(find.text('Order #2'), findsOneWidget);
      expect(find.text('Order #1'), findsNothing);
      expect(find.text('แสดง 1 จาก 3 รายการ'), findsOneWidget);
    });

    testWidgets('search matches game, uid and customer name', (tester) async {
      await _pump(tester, _FakeAdminOrderService(orders));

      await tester.enterText(find.byType(TextField), 'racing');
      await tester.pumpAndSettle();
      expect(find.text('Order #2'), findsOneWidget);
      expect(find.text('Order #1'), findsNothing);

      await tester.enterText(find.byType(TextField), '333');
      await tester.pumpAndSettle();
      expect(find.text('Order #3'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'bob');
      await tester.pumpAndSettle();
      expect(find.text('Order #3'), findsOneWidget);
      expect(find.text('Order #2'), findsNothing);
    });

    testWidgets('no match shows empty result and clear resets filters', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminOrderService(orders));

      await tester.enterText(find.byType(TextField), 'zzz-no-match');
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบคำสั่งซื้อที่ตรงกับการค้นหา'), findsOneWidget);

      await tester.tap(find.text('ล้างคำค้นหาและตัวกรอง'));
      await tester.pumpAndSettle();

      expect(find.text('Order #1'), findsOneWidget);
      expect(find.text('แสดง 3 จาก 3 รายการ'), findsOneWidget);
    });

    testWidgets('combined status + search narrows results', (tester) async {
      await _pump(tester, _FakeAdminOrderService(orders));

      await tester.tap(find.widgetWithText(ChoiceChip, 'เสร็จสิ้น'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'arena');
      await tester.pumpAndSettle();

      expect(find.text('Order #3'), findsOneWidget);
      expect(find.text('Order #1'), findsNothing);
      expect(find.text('ล้างตัวกรอง'), findsOneWidget);
    });
  });

  // กดปุ่ม → มี dialog ยืนยัน → เรียก service → รายการรีเฟรช
  group('actions', () {
    testWidgets('cancel: confirm calls service and refreshes status', (
      tester,
    ) async {
      final service = _FakeAdminOrderService([_order(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(_inCard('ยกเลิก'));
      await tester.pumpAndSettle();
      expect(find.text('ต้องการยกเลิก Order #1 ใช่หรือไม่?'), findsOneWidget);

      await tester.tap(find.text('ยกเลิกคำสั่งซื้อ'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'cancel:1', 'getAll']);
      expect(_inCard('ยกเลิก'), findsOneWidget); // เหลือแค่ chip สถานะ
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('cancel: choosing back does not call the service', (
      tester,
    ) async {
      final service = _FakeAdminOrderService([_order(1, 'Pending')]);
      await _pump(tester, service);

      await tester.tap(_inCard('ยกเลิก'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับ'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll']);
      expect(find.text('ยืนยันการยกเลิก'), findsNothing);
    });

    testWidgets('complete: confirm sets status Completed', (tester) async {
      final service = _FakeAdminOrderService([_order(1, 'Processing')]);
      await _pump(tester, service);

      await tester.tap(_inCard('เสร็จสิ้น'));
      await tester.pumpAndSettle();
      expect(
        find.text('ต้องการเปลี่ยน Order #1 เป็น Completed ใช่หรือไม่?'),
        findsOneWidget,
      );

      await tester.tap(find.text('ยืนยัน'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll', 'update:1:Completed', 'getAll']);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('complete: choosing back does not call the service', (
      tester,
    ) async {
      final service = _FakeAdminOrderService([_order(1, 'Processing')]);
      await _pump(tester, service);

      await tester.tap(_inCard('เสร็จสิ้น'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('กลับ'));
      await tester.pumpAndSettle();

      expect(service.calls, ['getAll']);
    });

    testWidgets('details dialog shows order breakdown and closes', (
      tester,
    ) async {
      await _pump(tester, _FakeAdminOrderService([_order(5, 'Pending')]));

      await tester.tap(find.text('รายละเอียด'));
      await tester.pumpAndSettle();

      expect(find.text('Order #5'), findsNWidgets(2)); // card + dialog title
      expect(find.text('Player UID'), findsOneWidget);
      expect(find.text('ราคาสินค้า'), findsOneWidget);
      expect(find.text('02/01/2026 12:05'), findsWidgets);

      await tester.tap(find.text('ปิด'));
      await tester.pumpAndSettle();
      expect(find.text('Player UID'), findsNothing);
    });
  });
}
