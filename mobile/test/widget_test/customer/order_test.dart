import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/order_view.dart';

import '../../support/fake_services.dart';

// Widget test หน้า "ยืนยันคำสั่งซื้อ" (CustomerOrderView) ฝั่ง customer
// ครอบคลุม: ฟอร์ม UID/Server, คูปอง, แต้มสะสม, สรุปราคา, การส่ง order
// และข้อความ error ที่ต่างกันตามที่ server ตอบกลับ

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

/// เกมที่ไม่ต้องกรอก Server ID (ใช้ testGame จาก fake_services)
final _game = testGame;

/// แพ็กเกจราคา 159 บาท
final _package = testPackage;

/// สร้างคูปองที่ "ใช้ได้" (active, ยังไม่ใช้, อยู่ในช่วงวันที่)
CustomerCouponModel _coupon({
  int id = 1,
  String code = 'SAVE50',
  String type = 'fixed',
  double value = 50,
  double minOrder = 0,
  double? maxDiscount,
  bool active = true,
  String? usedAt,
}) => CustomerCouponModel(
  userCouponId: id,
  couponId: id,
  code: code,
  discountType: type,
  discountValue: value,
  minOrderAmount: minOrder,
  maxDiscountAmount: maxDiscount,
  startDate: '2020-01-01T00:00:00',
  endDate: '2099-12-31T00:00:00',
  usedAt: usedAt,
  couponIsActive: active,
);

// ---------- Service ปลอม ----------

/// OrderService ปลอม: บันทึกข้อมูลที่ฟอร์มส่งมาใน [requests]
/// - [response] : สิ่งที่ server ตอบเมื่อสำเร็จ
/// - [error]    : ตั้งไว้เพื่อจำลอง server ตอบ error
/// - [gate]     : หน่วงการตอบ เพื่อดูสถานะ "กำลังสร้าง"
class _FakeCreateOrderService extends OrderService {
  _FakeCreateOrderService() : super(ApiService());

  Map<String, dynamic> response = {
    'order_id': 17,
    'total_amount': 159,
    'status': 'Pending',
  };
  Object? error;
  Completer<void>? gate;
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
    await gate?.future;
    if (error != null) throw error!;
    return response;
  }
}

/// PointService ปลอม: คืนยอดแต้มตาม [balance] หรือ throw ถ้าตั้ง [error]
class _FakePoints extends PointService {
  _FakePoints({this.balance = 1250, this.error}) : super(ApiService());
  final int balance;
  final Object? error;

  @override
  Future<int> getMyPoints() async {
    if (error != null) throw error!;
    return balance;
  }
}

/// UserCouponService ปลอม: คืน [coupons] หรือ throw ถ้าตั้ง [error]
class _FakeCoupons extends UserCouponService {
  _FakeCoupons({this.coupons = const [], this.error}) : super(ApiService());
  final List<CustomerCouponModel> coupons;
  final Object? error;

  @override
  Future<List<CustomerCouponModel>> getMyCoupons() async {
    if (error != null) throw error!;
    return coupons;
  }
}

/// เปิดหน้าสั่งซื้อพร้อม service ปลอมทั้งหมด
/// ขยายหน้าจอเทสต์ให้สูง เพื่อให้ทุกส่วนของฟอร์มอยู่ในจอและกดได้
Future<_FakeCreateOrderService> _pump(
  WidgetTester tester, {
  _FakeCreateOrderService? orders,
  GameModel? game,
  PackageModel? package,
  _FakePoints? points,
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
        Provider<PointService>.value(value: points ?? _FakePoints()),
        Provider<UserCouponService>.value(value: coupons ?? _FakeCoupons()),
        Provider<PaymentService>(create: (_) => FakePaymentService()),
      ],
      child: MaterialApp(
        home: CustomerOrderView(
          game: game ?? _game,
          package: package ?? _package,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return orderService;
}

// ช่องแรก = Player UID, ช่องสุดท้าย = จำนวนแต้ม
// (ถ้าเกมต้องมี Server ID จะเป็นช่องที่ 2)
Finder get _uidField => find.byType(TextFormField).first;
Finder get _serverField => find.byType(TextFormField).at(1);
Finder get _pointsField => find.byType(TextFormField).last;

// ปุ่มยืนยัน: ข้อความเดียวกับหัวข้อ AppBar จึงต้องจำกัดให้อยู่ใน ListView ของฟอร์ม
final _submit = find.descendant(
  of: find.byType(ListView),
  matching: find.text('ยืนยันคำสั่งซื้อ'),
);

/// เลือกคูปองจาก dropdown ตามข้อความที่แสดง
Future<void> _selectCoupon(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<int>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  // ---------- ส่วนแสดงผลของฟอร์ม ----------
  group('form layout', () {
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

    testWidgets('shows package summary and player section', (tester) async {
      await _pump(tester);

      expect(find.text('ยืนยันคำสั่งซื้อ'), findsNWidgets(2)); // title + button
      expect(find.text('แพ็กเกจที่เลือก'), findsOneWidget);
      expect(find.text('500 Diamonds'), findsOneWidget);
      expect(find.text('ข้อมูลผู้เล่น'), findsOneWidget);
      expect(find.text('฿159.00'), findsWidgets);
    });

    testWidgets('Server ID field only appears when the game needs it', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Server ID / Server Code'), findsNothing);
    });

    testWidgets('Server ID field and UID pattern hint show for server games', (
      tester,
    ) async {
      await _pump(tester, game: _serverGame);

      expect(find.text('Server ID / Server Code'), findsOneWidget);
      expect(find.text('รูปแบบ UID: ตัวเลข 9 หลัก'), findsOneWidget);
    });
  });

  // ---------- การตรวจข้อมูลก่อนส่ง ----------
  group('validation', () {
    testWidgets('empty UID is rejected and nothing is sent', (tester) async {
      final service = await _pump(tester);

      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอก Player UID'), findsOneWidget);
      expect(service.requests, isEmpty);
    });

    testWidgets('server game requires Server ID too', (tester) async {
      final service = await _pump(tester, game: _serverGame);

      await tester.enterText(_uidField, '123');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('กรุณากรอก Server ID'), findsOneWidget);
      expect(service.requests, isEmpty);
    });
  });

  // ---------- คูปอง ----------
  group('coupons', () {
    testWidgets('shows message when user has no coupons', (tester) async {
      await _pump(tester);

      expect(find.text('คุณยังไม่มีคูปองที่สามารถใช้ได้'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    });

    testWidgets(
      'shows message when coupons fail to load, order still allowed',
      (tester) async {
        await _pump(
          tester,
          coupons: _FakeCoupons(
            error: const ApiException(statusCode: 500, message: 'x'),
          ),
        );

        expect(
          find.text(
            'ไม่สามารถโหลดคูปองได้ คุณยังสามารถสร้างคำสั่งซื้อโดยไม่ใช้คูปอง',
          ),
          findsOneWidget,
        );
        expect(_submit, findsOneWidget);
      },
    );

    testWidgets('hides coupons that are used, inactive or below min order', (
      tester,
    ) async {
      await _pump(
        tester,
        coupons: _FakeCoupons(
          coupons: [
            _coupon(id: 1, code: 'USED', usedAt: '2026-01-01T00:00:00'),
            _coupon(id: 2, code: 'OFF', active: false),
            _coupon(id: 3, code: 'BIG', minOrder: 1000),
          ],
        ),
      );

      expect(
        find.text('ไม่มีคูปองที่เข้าเงื่อนไขยอดซื้อของแพ็กเกจนี้'),
        findsOneWidget,
      );
    });

    testWidgets('fixed coupon reduces the estimated total', (tester) async {
      await _pump(tester, coupons: _FakeCoupons(coupons: [_coupon()]));

      await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');

      expect(find.text('เลือกคูปอง SAVE50 แล้ว'), findsOneWidget);
      expect(find.text('-฿50.00'), findsWidgets); // preview + summary
      expect(find.text('฿109.00'), findsWidgets); // 159 - 50
    });

    testWidgets('percent coupon is capped by its max discount', (tester) async {
      // 50% ของ 159 = 79.50 แต่จำกัดสูงสุด 30
      await _pump(
        tester,
        coupons: _FakeCoupons(
          coupons: [
            _coupon(code: 'HALF', type: 'percent', value: 50, maxDiscount: 30),
          ],
        ),
      );

      await _selectCoupon(tester, 'HALF - ลด 50%');

      expect(find.text('-฿30.00'), findsWidgets);
      expect(find.text('฿129.00'), findsWidgets); // 159 - 30
    });

    testWidgets('discount never exceeds the package price', (tester) async {
      await _pump(
        tester,
        coupons: _FakeCoupons(coupons: [_coupon(code: 'HUGE', value: 500)]),
      );

      await _selectCoupon(tester, 'HUGE - ลด ฿500.00');

      expect(find.text('-฿159.00'), findsWidgets);
      expect(find.text('฿0.00'), findsWidgets);
    });

    testWidgets('choosing "no coupon" removes the discount again', (
      tester,
    ) async {
      await _pump(tester, coupons: _FakeCoupons(coupons: [_coupon()]));

      await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');
      await _selectCoupon(tester, 'ไม่ใช้คูปอง');

      expect(find.text('เลือกคูปอง SAVE50 แล้ว'), findsNothing);
      expect(find.text('ส่วนลดคูปอง'), findsNothing);
    });
  });

  // ---------- แต้มสะสม (10 แต้ม = 1 บาท) ----------
  group('points', () {
    testWidgets('shows balance and the maximum usable points', (tester) async {
      await _pump(tester);

      expect(find.text('1250 แต้ม'), findsOneWidget);
      expect(find.text('ใช้ได้สูงสุด 1250 แต้ม'), findsOneWidget);
    });

    testWidgets('typing points shows discount and lowers the total', (
      tester,
    ) async {
      await _pump(tester);

      await tester.enterText(_pointsField, '100');
      await tester.pumpAndSettle();

      expect(find.text('-฿10.00'), findsWidgets); // 100 แต้ม = 10 บาท
      expect(find.text('฿149.00'), findsWidgets); // 159 - 10
    });

    testWidgets('points above the balance are clamped to the balance', (
      tester,
    ) async {
      await _pump(tester, points: _FakePoints(balance: 40));

      await tester.enterText(_pointsField, '999');
      await tester.pumpAndSettle();

      expect(find.text('ใช้ได้สูงสุด 40 แต้ม'), findsOneWidget);
      expect(find.text('-฿4.00'), findsWidgets); // 40 แต้ม = 4 บาท
    });

    testWidgets('points are capped so they cannot exceed the price', (
      tester,
    ) async {
      // ราคา 159 → ใช้แต้มได้สูงสุด 1590 แม้มีแต้ม 5000
      await _pump(tester, points: _FakePoints(balance: 5000));

      expect(find.text('ใช้ได้สูงสุด 1590 แต้ม'), findsOneWidget);
    });

    testWidgets('selecting a coupon lowers the maximum usable points', (
      tester,
    ) async {
      await _pump(
        tester,
        points: _FakePoints(balance: 5000),
        coupons: _FakeCoupons(coupons: [_coupon()]),
      );

      await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');

      // (159 - 50) * 10 = 1090
      expect(find.text('ใช้ได้สูงสุด 1090 แต้ม'), findsOneWidget);
    });

    testWidgets('zero balance disables the points field', (tester) async {
      await _pump(tester, points: _FakePoints(balance: 0));

      final field = tester.widget<TextFormField>(_pointsField);
      expect(field.enabled, isFalse);
    });

    testWidgets('shows message when points fail to load', (tester) async {
      await _pump(
        tester,
        points: _FakePoints(
          error: const ApiException(statusCode: 500, message: 'x'),
        ),
      );

      expect(
        find.text(
          'ไม่สามารถโหลดแต้มสะสมได้ คุณยังสามารถสร้างคำสั่งซื้อโดยไม่ใช้แต้ม',
        ),
        findsOneWidget,
      );
    });
  });

  // ---------- การส่ง order สำเร็จ ----------
  group('submit', () {
    testWidgets('sends trimmed UID/server, coupon and points', (tester) async {
      final service = await _pump(
        tester,
        game: _serverGame,
        coupons: _FakeCoupons(coupons: [_coupon(id: 7)]),
      );

      await tester.enterText(_uidField, '  123456789 ');
      await tester.enterText(_serverField, ' TH-01 ');
      await _selectCoupon(tester, 'SAVE50 - ลด ฿50.00');
      await tester.enterText(_pointsField, '100');
      await tester.pumpAndSettle();
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(service.requests.single, {
        'packageId': 2,
        'playerUid': '123456789',
        'serverCode': 'TH-01',
        'couponId': 7,
        'spentPoints': 100,
      });
    });

    testWidgets('without coupon/points sends null coupon and 0 points', (
      tester,
    ) async {
      final service = await _pump(tester);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(service.requests.single['couponId'], isNull);
      expect(service.requests.single['spentPoints'], 0);
      expect(service.requests.single['serverCode'], '');
    });

    testWidgets('success view shows server-calculated amounts', (tester) async {
      final service = _FakeCreateOrderService()
        ..response = {
          'order_id': 17,
          'total_amount': 99,
          'coupon_discount': 50,
          'point_discount': 10,
          'spent_points': 100,
          'discount_amount': 60,
          'status': 'Pending',
        };
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(
        find.text('สร้างคำสั่งซื้อสำเร็จ'),
        findsNWidgets(2),
      ); // title + body
      expect(find.text('#17'), findsOneWidget);
      expect(find.text('111'), findsOneWidget); // Player UID
      expect(find.text('-฿50.00'), findsOneWidget); // ส่วนลดคูปอง
      expect(find.text('100 แต้ม'), findsOneWidget);
      expect(find.text('-฿10.00'), findsOneWidget); // ส่วนลดจากแต้ม
      expect(find.text('-฿60.00'), findsOneWidget); // ส่วนลดรวม
      expect(find.text('฿99.00'), findsOneWidget); // ยอดคำสั่งซื้อ
      expect(find.text('Pending'), findsOneWidget);
    });

    testWidgets('button is disabled and relabelled while submitting', (
      tester,
    ) async {
      final service = _FakeCreateOrderService()..gate = Completer<void>();
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pump();

      expect(find.text('กำลังสร้างคำสั่งซื้อ...'), findsOneWidget);
      final button = tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text('กำลังสร้างคำสั่งซื้อ...'),
          matching: find.bySubtype<ElevatedButton>(),
        ),
      );
      expect(button.onPressed, isNull);

      service.gate!.complete();
      await tester.pumpAndSettle();
      expect(service.requests, hasLength(1));
    });

    testWidgets('"แจ้งการชำระเงิน" opens the payment page for this order', (
      tester,
    ) async {
      final service = _FakeCreateOrderService()
        ..response = {'order_id': 17, 'total_amount': 120, 'status': 'Pending'};
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      await tester.tap(find.text('แจ้งการชำระเงิน'));
      await tester.pumpAndSettle();

      // หน้าชำระเงินแสดงยอดที่ server คำนวณ ไม่ใช่ราคาแพ็กเกจ
      expect(find.text('ช่องทางการชำระเงิน'), findsOneWidget);
      expect(find.text('฿120.00'), findsOneWidget);
    });
  });

  // ---------- ข้อความ error ตามที่ server ตอบ ----------
  group('server errors', () {
    // แต่ละเคส: error ที่ server ตอบ → ข้อความที่ผู้ใช้ควรเห็น
    final cases = <String, (ApiException, String)>{
      '400 coupon': (
        const ApiException(statusCode: 400, message: 'Invalid coupon'),
        'คูปองนี้ไม่สามารถใช้งานได้แล้ว กรุณาเลือกคูปองอื่นหรือลองใหม่',
      ),
      '400 order amount': (
        const ApiException(statusCode: 400, message: 'Order amount too low'),
        'ยอดซื้อไม่ถึงขั้นต่ำของคูปอง',
      ),
      '400 server': (
        const ApiException(statusCode: 400, message: 'Invalid server'),
        'กรุณาตรวจสอบ Server ID',
      ),
      '400 insufficient points': (
        const ApiException(statusCode: 400, message: 'Insufficient points'),
        'แต้มสะสมของคุณไม่เพียงพอ กรุณาปรับจำนวนแต้มที่ต้องการใช้',
      ),
      '400 point discount': (
        const ApiException(statusCode: 400, message: 'Point discount too high'),
        'จำนวนแต้มที่ใช้มากเกินยอดเงินที่เหลือ หลังหักส่วนลดคูปอง',
      ),
      '400 other': (
        const ApiException(statusCode: 400, message: 'bad'),
        'ข้อมูลคำสั่งซื้อไม่ถูกต้อง กรุณาตรวจสอบ UID และข้อมูลที่กรอก',
      ),
      '401': (
        const ApiException(statusCode: 401, message: 'x'),
        'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่',
      ),
      '403': (
        const ApiException(statusCode: 403, message: 'x'),
        'บัญชีผู้ใช้งานนี้ไม่สามารถสร้างคำสั่งซื้อได้',
      ),
      '404': (
        const ApiException(statusCode: 404, message: 'x'),
        'ไม่พบแพ็กเกจที่เลือก หรือแพ็กเกจถูกปิดใช้งานแล้ว',
      ),
      '409': (
        const ApiException(statusCode: 409, message: 'x'),
        'ไม่สามารถสร้างคำสั่งซื้อได้ กรุณาตรวจสอบแพ็กเกจหรือคูปองอีกครั้ง',
      ),
      '500 uses server message': (
        const ApiException(statusCode: 500, message: 'db down'),
        'db down',
      ),
    };

    cases.forEach((name, testCase) {
      testWidgets(name, (tester) async {
        final service = _FakeCreateOrderService()..error = testCase.$1;
        await _pump(tester, orders: service);

        await tester.enterText(_uidField, '111');
        await tester.tap(_submit);
        await tester.pumpAndSettle();

        expect(find.text(testCase.$2), findsOneWidget);
        expect(find.text('สร้างคำสั่งซื้อสำเร็จ'), findsNothing);
        expect(_submit, findsOneWidget); // ยังกดส่งซ้ำได้
      });
    });

    testWidgets('unexpected error shows generic message', (tester) async {
      final service = _FakeCreateOrderService()..error = StateError('x');
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่สามารถสร้างคำสั่งซื้อได้ กรุณาลองใหม่อีกครั้ง'),
        findsOneWidget,
      );
    });

    testWidgets('response without order_id is treated as an error', (
      tester,
    ) async {
      final service = _FakeCreateOrderService()..response = {'status': 'ok'};
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(find.text('ไม่พบหมายเลขคำสั่งซื้อจากเซิร์ฟเวอร์'), findsOneWidget);
    });

    testWidgets('error disappears after a successful retry', (tester) async {
      final service = _FakeCreateOrderService()
        ..error = const ApiException(statusCode: 404, message: 'x');
      await _pump(tester, orders: service);

      await tester.enterText(_uidField, '111');
      await tester.tap(_submit);
      await tester.pumpAndSettle();
      expect(
        find.text('ไม่พบแพ็กเกจที่เลือก หรือแพ็กเกจถูกปิดใช้งานแล้ว'),
        findsOneWidget,
      );

      service.error = null;
      await tester.tap(_submit);
      await tester.pumpAndSettle();

      expect(
        find.text('ไม่พบแพ็กเกจที่เลือก หรือแพ็กเกจถูกปิดใช้งานแล้ว'),
        findsNothing,
      );
      expect(find.text('#17'), findsOneWidget);
    });
  });
}
