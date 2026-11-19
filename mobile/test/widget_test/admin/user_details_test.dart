import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/admin/user_admin_model.dart';
import 'package:mobile/model/admin/user_details_model.dart';
import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/view/admin/user_details_view.dart';

class _FakeUserManagementService extends UserManagementService {
  _FakeUserManagementService() : super(ApiService());

  UserDetailsModel? detailsToReturn;
  Object? error;
  int requestedUserIdsCount = 0;

  @override
  Future<UserDetailsModel> getUserDetails(int userId) async {
    requestedUserIdsCount++;
    if (error != null) throw error!;
    return detailsToReturn!;
  }
}

UserDetailsModel _sampleDetails({bool isActive = true}) {
  return UserDetailsModel(
    user: AdminUserModel(
      userId: 10,
      username: 'gamer_ten',
      email: 'gamer10@example.com',
      displayName: 'Gamer Ten',
      role: 'user',
      isActive: isActive,
      createdAt: '2026-10-15T09:30:00.000Z',
    ),
    orderCount: 2,
    paymentCount: 1,
    paidAmount: 299.0,
    pointBalance: 150,
    receiptCount: 1,
    couponCount: 1,
    orders: [
      {
        'order_id': 101,
        'game_name_snapshot': 'Arena Test',
        'package_name_snapshot': '500 Diamonds',
        'player_uid': '99887766',
        'server_code': 'TH-01',
        'created_at': '2026-10-16T10:00:00.000Z',
        'status': 'Completed',
        'discount_amount': 0,
        'total_amount': 299,
      },
    ],
    payments: [
      {
        'payment_id': 201,
        'order_id': 101,
        'game_name_snapshot': 'Arena Test',
        'package_name_snapshot': '500 Diamonds',
        'transaction_ref': 'TX-101',
        'method': 'PromptPay',
        'created_at': '2026-10-16T10:01:00.000Z',
        'status': 'Paid',
        'amount': 299,
      },
    ],
    pointTransactions: [
      {
        'point_transaction_id': 301,
        'event_key': 'order_complete',
        'type': 'Earn',
        'order_id': 101,
        'created_at': '2026-10-16T10:02:00.000Z',
        'points_delta': 30,
      },
    ],
    receipts: [
      {
        'receipt_id': 401,
        'receipt_number': 'PG-000101',
        'order_id': 101,
        'game_name_snapshot': 'Arena Test',
        'package_name_snapshot': '500 Diamonds',
        'issued_at': '2026-10-16T10:02:00.000Z',
      },
    ],
    userCoupons: [
      {
        'user_coupon_id': 501,
        'code': 'WELCOME50',
        'discount_type': 'fixed',
        'discount_value': 50,
        'end_date': '2026-12-31T23:59:59.000Z',
        'used_at': null,
      },
    ],
  );
}

Future<void> _pumpDetailsView(
  WidgetTester tester,
  _FakeUserManagementService service, {
  int userId = 10,
}) async {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<UserManagementService>.value(
      value: service,
      child: MaterialApp(home: UserDetailsView(userId: userId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders user profile, summary cards, and history sections', (
    tester,
  ) async {
    final service = _FakeUserManagementService()
      ..detailsToReturn = _sampleDetails(isActive: true);

    await _pumpDetailsView(tester, service);

    // ข้อมูลโปรไฟล์
    expect(find.text('รายละเอียดสมาชิก'), findsOneWidget);
    expect(find.text('Gamer Ten'), findsOneWidget);
    expect(find.text('@gamer_ten'), findsOneWidget);
    expect(find.text('gamer10@example.com'), findsOneWidget);
    expect(find.text('บัญชีเปิดใช้งาน'), findsOneWidget);
    expect(find.text('User ID: 10'), findsOneWidget);

    // การ์ดภาพรวมการใช้งาน
    expect(find.text('ภาพรวมการใช้งาน'), findsOneWidget);
    expect(find.text('฿299.00'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);

    // หมวดประวัติการใช้งาน
    expect(find.text('ประวัติการใช้งาน'), findsOneWidget);
    expect(find.text('การชำระเงิน'), findsWidgets);
    expect(find.text('ประวัติแต้ม'), findsOneWidget);
    expect(find.text('คูปองของสมาชิก'), findsOneWidget);
  });

  testWidgets('expands order section to show order items', (tester) async {
    final service = _FakeUserManagementService()
      ..detailsToReturn = _sampleDetails();

    await _pumpDetailsView(tester, service);

    await tester.tap(find.widgetWithText(ExpansionTile, 'คำสั่งซื้อ'));
    await tester.pumpAndSettle();

    expect(find.text('Order #101'), findsOneWidget);
    expect(find.text('UID: 99887766'), findsOneWidget);
    expect(find.text('Server: TH-01'), findsOneWidget);
  });

  testWidgets('shows error state and retries when loading fails', (
    tester,
  ) async {
    final service = _FakeUserManagementService()
      ..error = const ApiException(statusCode: 500, message: 'โหลดข้อมูลไม่สำเร็จ');

    await _pumpDetailsView(tester, service);

    expect(find.text('โหลดข้อมูลไม่สำเร็จ'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    // จำลองการกดลองอีกครั้งแล้วสำเร็จ
    service
      ..error = null
      ..detailsToReturn = _sampleDetails();

    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('Gamer Ten'), findsOneWidget);
    expect(service.requestedUserIdsCount, 2);
  });
}