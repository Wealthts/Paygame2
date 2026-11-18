import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/order_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/model/payment_model.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/model/user_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/auth_service.dart';
import 'package:mobile/service/customer/customer_game_service.dart';
import 'package:mobile/service/customer/customer_package_service.dart';
import 'package:mobile/service/customer/customer_profile_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/service/user_coupon_service.dart';

final testUser = UserModel(
  userId: 10,
  username: 'test_player',
  email: 'test@example.com',
  displayName: 'Test Player',
  role: 'user',
);

final testGame = GameModel(
  gameId: 1,
  gameName: 'Arena Test',
  category: 'MOBA',
  uidPattern: 'numeric',
  requiresServer: false,
  imageUrl: '',
  isActive: true,
);

final testPackage = PackageModel(
  packageId: 2,
  gameId: 1,
  packageName: '500 Diamonds',
  gameName: 'Arena Test',
  price: 159,
  isActive: true,
  requiresServer: false,
);

final testPoint = PointModel(
  pointTransactionId: 1,
  userId: 10,
  eventKey: 'order_complete',
  type: 'Earn',
  pointsDelta: 25,
  createdAt: DateTime(2026, 1, 2, 12),
);

final testOrder = OrderModel(
  orderId: 17,
  userId: 10,
  packageId: 2,
  playerUid: '123456789',
  serverCode: '',
  gameName: 'Arena Test',
  packageName: '500 Diamonds',
  status: 'Completed',
  paymentStatus: 'Paid',
  originalPrice: 159,
  discountAmount: 0,
  totalAmount: 159,
  couponDiscount: 0,
  feeAmount: 0,
  spentPoints: 0,
  createdAt: DateTime(2026, 1, 2, 12),
);

final testPayment = PaymentModel(
  paymentId: 3,
  orderId: 17,
  transactionRef: 'TX-TEST-001',
  method: 'PromptPay',
  amount: 159,
  status: 'Pending',
  gameName: 'Arena Test',
  packageName: '500 Diamonds',
);

final testReceipt = ReceiptModel(
  receiptId: 5,
  orderId: 17,
  receiptNumber: 'PG-TEST-0005',
  issuedAt: DateTime(2026, 1, 2, 12),
  gameName: 'Arena Test',
  packageName: '500 Diamonds',
  totalAmount: 159,
);

class FakeAuthService extends AuthService {
  FakeAuthService() : super(ApiService());

  @override
  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String displayName,
    required bool acceptedTerms,
  }) async {}

  @override
  Future<void> requestPasswordReset({required String email}) async {}

  @override
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {}

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async => testUser;

  @override
  Future<UserModel?> restoreSession() async => null;

  @override
  Future<void> logout() async {}
}

class FakeCustomerGameService extends CustomerGameService {
  FakeCustomerGameService() : super(ApiService());
  @override
  Future<List<GameModel>> getActiveGames() async => [testGame];
}

class FakeCustomerPackageService extends CustomerPackageService {
  FakeCustomerPackageService() : super(ApiService());
  @override
  Future<List<PackageModel>> getPackagesByGame(int gameId) async => [
    testPackage,
  ];
}

class FakePointService extends PointService {
  FakePointService() : super(ApiService());
  @override
  Future<int> getMyPoints() async => 1250;
  @override
  Future<List<PointModel>> getMyPointHistory() async => [testPoint];
}

class FakeOrderService extends OrderService {
  FakeOrderService() : super(ApiService());
  @override
  Future<List<OrderModel>> getMyOrders() async => [testOrder];
}

class FakePaymentService extends PaymentService {
  FakePaymentService() : super(ApiService());
  @override
  Future<List<PaymentModel>> getMyPayments() async => [testPayment];
}

class FakeReceiptService extends ReceiptService {
  FakeReceiptService() : super(ApiService());
  @override
  Future<List<ReceiptModel>> getMyReceipts() async => [testReceipt];
}

class FakeUserCouponService extends UserCouponService {
  FakeUserCouponService() : super(ApiService());
  @override
  Future<List<CustomerCouponModel>> getMyCoupons() async => [];
}

class FakeCustomerProfileService extends CustomerProfileService {
  FakeCustomerProfileService() : super(ApiService());
  @override
  Future<UserModel> getMyProfile() async => testUser;
}

Widget withAuthController(Widget child) {
  return ChangeNotifierProvider<AuthController>(
    create: (_) => AuthController(FakeAuthService()),
    child: MaterialApp(home: child),
  );
}
