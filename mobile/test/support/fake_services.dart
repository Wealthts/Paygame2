import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/order_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/model/payment_model.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/model/user_model.dart';
import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/auth_service.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/customer/customer_game_service.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/service/package_service.dart';
import 'package:mobile/service/customer/customer_package_service.dart';
import 'package:mobile/service/customer/customer_profile_service.dart';
import 'package:mobile/service/coupon_service.dart';
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

// Shared report fixtures: use these values for repeatable widget/unit expectations.
const testReportSummary = ReportSummary(
  totalOrders: 10,
  pendingOrders: 2,
  completedOrders: 7,
  cancelledOrders: 1,
  paidPaymentCount: 7,
  totalRevenue: 1200.5,
  totalMembers: 4,
);

const testAdminReport = AdminReportModel(
  summary: testReportSummary,
  monthlyRevenue: [
    MonthlyRevenueModel(month: '2026-01', revenue: 500, paymentCount: 3),
    MonthlyRevenueModel(month: '2026-02', revenue: 700.5, paymentCount: 4),
  ],
  topGames: [
    TopGameModel(gameName: 'Arena Test', orderCount: 7, completedSales: 900),
    TopGameModel(gameName: 'Racing Pro', orderCount: 3, completedSales: 300.5),
  ],
  orderStatuses: [
    OrderStatusModel(status: 'Completed', orderCount: 7),
    OrderStatusModel(status: 'Pending', orderCount: 2),
    OrderStatusModel(status: 'Cancelled', orderCount: 1),
  ],
);

/// In-memory ReportService substitute for widget and controller tests.
/// Configure summaryError/reportError and inspect *Calls counters for behavior assertions.
class FakeReportService extends ReportService {
  FakeReportService({
    this.summary = testReportSummary,
    this.report = testAdminReport,
  }) : super(ApiService());

  ReportSummary summary;
  AdminReportModel report;
  Object? summaryError;
  Object? reportError;
  int summaryCalls = 0;
  int reportCalls = 0;

  @override
  Future<ReportSummary> getSummary() async {
    summaryCalls++;
    if (summaryError != null) throw summaryError!;
    return summary;
  }

  @override
  Future<AdminReportModel> getAdminReport() async {
    reportCalls++;
    if (reportError != null) throw reportError!;
    return report;
  }
}

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

class FakeCouponService extends CouponService {
  FakeCouponService({this.coupons = const []}) : super(ApiService());

  final List<CouponModel> coupons;
  Map<String, dynamic>? createdCoupon;
  final List<(int, bool)> statusChanges = [];

  @override
  Future<List<CouponModel>> getAllCoupons() async => coupons;

  @override
  Future<void> createCoupon(Map<String, dynamic> body) async {
    createdCoupon = body;
  }

  @override
  Future<void> updateCouponStatus(int couponId, bool isActive) async {
    statusChanges.add((couponId, isActive));
  }
}

class FakeUserCouponService extends UserCouponService {
  FakeUserCouponService({
    this.customerCoupons = const [],
    this.userCoupons = const [],
    this.availableUsers = const [],
  }) : super(ApiService());

  final List<CustomerCouponModel> customerCoupons;
  final List<UserCouponModel> userCoupons;
  final List<UserOptionModel> availableUsers;
  String? claimedCode;
  int? assignedUserId;
  int? assignedCouponId;

  @override
  Future<List<UserCouponModel>> getAllUserCoupons() async => userCoupons;

  @override
  Future<List<UserOptionModel>> getAvailableUsers() async => availableUsers;

  @override
  Future<List<CustomerCouponModel>> getMyCoupons() async => customerCoupons;

  @override
  Future<void> claimCouponByCode(String code) async {
    claimedCode = code;
  }

  @override
  Future<void> assignCoupon({
    required int userId,
    required int couponId,
  }) async {
    assignedUserId = userId;
    assignedCouponId = couponId;
  }
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


// Fake services for admin game/package tests.
class FakeGameService extends GameService {
  FakeGameService() : super(ApiService());

  final List<GameModel> items = [testGame];

  @override
  Future<List<GameModel>> getAllGames() async => List<GameModel>.from(items);

  @override
  Future<void> createGame(Map<String, dynamic> data) async {
    items.add(GameModel.fromJson({
      ...data,
      'game_id': items.length + 1,
    }));
  }

  @override
  Future<void> updateGame(int gameId, Map<String, dynamic> data) async {
    final index = items.indexWhere((game) => game.gameId == gameId);
    if (index >= 0) {
      items[index] = GameModel.fromJson({...data, 'game_id': gameId});
    }
  }

  @override
  Future<void> updateGameStatus(int gameId, bool isActive) async {
    final index = items.indexWhere((game) => game.gameId == gameId);
    if (index >= 0) {
      final game = items[index];
      items[index] = GameModel(
        gameId: game.gameId,
        gameName: game.gameName,
        category: game.category,
        uidPattern: game.uidPattern,
        requiresServer: game.requiresServer,
        imageUrl: game.imageUrl,
        isActive: isActive,
      );
    }
  }
}

class FakePackageService extends PackageService {
  FakePackageService() : super(ApiService());

  final List<PackageModel> items = [testPackage];

  @override
  Future<List<PackageModel>> getAllPackages() async =>
      List<PackageModel>.from(items);

  @override
  Future<void> createPackage(Map<String, dynamic> data) async {
    items.add(PackageModel.fromJson({
      ...data,
      'package_id': items.length + 1,
      'game_name': testGame.gameName,
      'requires_server': testGame.requiresServer ? 1 : 0,
    }));
  }

  @override
  Future<void> updatePackage(int packageId, Map<String, dynamic> data) async {
    final index = items.indexWhere((item) => item.packageId == packageId);
    if (index >= 0) {
      items[index] = PackageModel.fromJson({
        ...data,
        'package_id': packageId,
        'game_name': testGame.gameName,
        'requires_server': testGame.requiresServer ? 1 : 0,
      });
    }
  }

  @override
  Future<void> updatePackageStatus(int packageId, bool isActive) async {
    final index = items.indexWhere((item) => item.packageId == packageId);
    if (index >= 0) {
      final item = items[index];
      items[index] = PackageModel(
        packageId: item.packageId,
        gameId: item.gameId,
        packageName: item.packageName,
        gameName: item.gameName,
        price: item.price,
        isActive: isActive,
        requiresServer: item.requiresServer,
      );
    }
  }
}
