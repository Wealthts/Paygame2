import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/order_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "ยืนยันคำสั่งซื้อ" ฝั่ง customer
// ครอบคลุม: ฟอร์ม UID/Server, คูปอง, แต้มสะสม, การส่ง order และ error

// ---------- ข้อมูลทดสอบ ----------

/// เกมที่ต้องกรอก Server ID
final _serverGame = GameModel(
  gameId: 1,
  gameName: 'Arena Test',
  category: 'MOBA',
  uidPattern: 'ตัวเลข 9 หลัก',
  requiresServer: true,
  imageUrl: '',
  isActive: true,
);

/// คูปองลด 50 บาท ที่ใช้งานได้
CustomerCouponModel _coupon({int id = 1}) => CustomerCouponModel(
  userCouponId: id,
  couponId: id,
  code: 'SAVE50',
  discountType: 'fixed',
  discountValue: 50,
  minOrderAmount: 0,
  maxDiscountAmount: null,
  startDate: '2020-01-01T00:00:00',
  endDate: '2099-12-31T00:00:00',
  usedAt: null,
  couponIsActive: true,
);

// ---------- Service ปลอม ----------

/// OrderService ปลอม: เก็บข้อมูลที่ฟอร์มส่งมาไว้ใน [requests]
/// ตั้ง [error] เพื่อจำลองว่า server ตอบ error
class _FakeCreateOrderService extends OrderService {
  _FakeCreateOrderService() : super(ApiService());

  Object? error;
  final requests = <Map<String, Object?>>[];

  @override
  Future<Map<String, dynamic>> createOrder({
    required int packageId,
    required String playerUid,
    String serverCode = '',
    int? couponId,
    int spentPoints = 0,
  }) async {
    requests.add({
      'packageId': packageId,
      'playerUid': playerUid,
      'serverCode': serverCode,
      'couponId': couponId,
      'spentPoints': spentPoints,
    });
    if (error != null) throw error!;
    return {'order_id': 17, 'total_amount': 159, 'status': 'Pending'};
  }
}

/// PointService ปลอม: มีแต้ม 1250
class _FakePoints extends PointService {
  _FakePoints() : super(ApiService());

  @override
  Future<int> getMyPoints() async => 1250;
}

/// UserCouponService ปลอม: คืนคูปองตาม [coupons]
class _FakeCoupons extends UserCouponService {
  _FakeCoupons([this.coupons = const []]) : super(ApiService());
  final List<CustomerCouponModel> coupons;

  @override
  Future<List<CustomerCouponModel>> getMyCoupons() async => coupons;
}

/// เปิดหน้าสั่งซื้อพร้อม service ปลอม (จอสูงเพื่อให้ทุกส่วนของฟอร์มกดได้)
Future<_FakeCreateOrderService> _pump(
  WidgetTester tester, {
  _FakeCreateOrderService? orders,
  GameModel? game,
  _FakeCoupons? coupons,
}) async {
  tester.view.physicalSize = const Size(800, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final orderService = orders ?? _FakeCreateOrderService();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<OrderService>.value(value: orderService),
        Provider<PointService>.value(value: _FakePoints()),
        Provider<UserCouponService>.value(value: coupons ?? _FakeCoupons()),
        Provider<PaymentService>(create: (_) => FakePaymentService()),
      ],
      child: MaterialApp(
        home: CustomerOrderView(game: game ?? testGame, package: testPackage),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return orderService;
}

// ช่องแรก = Player UID, ช่องที่ 2 = Server ID (ถ้ามี), ช่องสุดท้าย = จำนวนแต้ม
Finder get _uidField => find.byType(TextFormField).first;
Finder get _serverField => find.byType(TextFormField).at(1);
Finder get _pointsField => find.byType(TextFormField).last;

// ปุ่มยืนยัน (ข้อความซ้ำกับหัว AppBar จึงหาเฉพาะใน ListView ของฟอร์ม)
final _submit = find.descendant(
  of: find.byType(ListView),
  matching: find.text('ยืนยันคำสั่งซื้อ'),
);

/// เลือกคูปองจาก dropdown
Future<void> _selectCoupon(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  // เทสต์เดิม
  testWidgets('order page renders player information and order summary', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OrderService>(create: (_) => FakeOrderService()),
          Provider<PointService>(create: (_) => FakePointService()),
          Provider<UserCouponService>(create: (_) => FakeUserCouponService()),
        ],
        child: MaterialApp(
          home: CustomerOrderView(game: testGame, package: testPackage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ข้อมูลผู้เล่น'), findsOneWidget);
    expect(find.text('500 Diamonds'), findsOneWidget);
  });

  testWidgets('Server ID field shows only for games that need it', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Server ID / Server Code'), findsNothing);

    await _pump(tester, game: _serverGame);
    expect(find.text('Server ID / Server Code'), findsOneWidget);
  });

  testWidgets('empty UID is rejected and nothing is sent', (tester) async {
    final service = await _pump(tester);

    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('กรุณากรอก Player UID'), findsOneWidget);
    expect(service.requests, isEmpty);
  });

  testWidgets('coupon reduces the total', (tester) async {
    await _pump(tester, coupons: _FakeCoupons([_coupon()]));

    await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');

    expect(find.text('฿109.00'), findsWidgets); // 159 - 50
  });

  testWidgets('points reduce the total (10 points = 1 baht)', (tester) async {
    await _pump(tester);

    await tester.enterText(_pointsField, '100');
    await tester.pumpAndSettle();

    expect(find.text('฿149.00'), findsWidgets); // 159 - 10
  });

  testWidgets('submit sends the form data and shows success', (tester) async {
    final service = await _pump(
      tester,
      game: _serverGame,
      coupons: _FakeCoupons([_coupon(id: 7)]),
    );

    await tester.enterText(_uidField, ' 123456789 ');
    await tester.enterText(_serverField, 'TH-01');
    await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');
    await tester.enterText(_pointsField, '100');
    await tester.pumpAndSettle();
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(service.requests.single, {
      'packageId': 2,
      'playerUid': '123456789', // ตัดช่องว่างหน้า-หลังแล้ว
      'serverCode': 'TH-01',
      'couponId': 7,
      'spentPoints': 100,
    });
    expect(find.text('#17'), findsOneWidget);
  });

  testWidgets('server error shows a message and keeps the form', (
    tester,
  ) async {
    final service = _FakeCreateOrderService()
      ..error = const ApiException(statusCode: 401, message: 'x');
    await _pump(tester, orders: service);

    await tester.enterText(_uidField, '111');
    await tester.tap(_submit);
    await tester.pumpAndSettle();

    expect(find.text('เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่'), findsOneWidget);
    expect(_submit, findsOneWidget); // ยังกดส่งใหม่ได้
  });
}
