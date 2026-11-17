import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/app_theme.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/auth_service.dart';
import 'package:mobile/service/game_service.dart';
import 'package:mobile/service/package_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/payment_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/receipt_service.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/service/admin/user_management_service.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/customer/customer_game_service.dart';
import 'package:mobile/service/customer/customer_package_service.dart';
import 'package:mobile/service/customer/customer_profile_service.dart';
import 'package:mobile/view/auth/index_view.dart';
import 'package:mobile/view/admin/homepage_view.dart';
import 'package:mobile/view/customer/homepage_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create: (_) => ApiService(),
          dispose: (_, service) => service.dispose(),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(context.read<ApiService>()),
        ),
        Provider<GameService>(
          create: (context) => GameService(context.read<ApiService>()),
        ),
        Provider<CustomerGameService>(
          create: (context) => CustomerGameService(context.read<ApiService>()),
        ),
        Provider<PackageService>(
          create: (context) => PackageService(context.read<ApiService>()),
        ),
        Provider<CustomerPackageService>(
          create: (context) =>
              CustomerPackageService(context.read<ApiService>()),
        ),
        Provider<OrderService>(
          create: (context) => OrderService(context.read<ApiService>()),
        ),
        Provider<PaymentService>(
          create: (context) => PaymentService(context.read<ApiService>()),
        ),
        Provider<PointService>(
          create: (context) => PointService(context.read<ApiService>()),
        ),
        Provider<ReceiptService>(
          create: (context) => ReceiptService(context.read<ApiService>()),
        ),
        Provider<CouponService>(
          create: (context) => CouponService(context.read<ApiService>()),
        ),
        Provider<UserCouponService>(
          create: (context) => UserCouponService(context.read<ApiService>()),
        ),
        Provider<UserManagementService>(
          create: (context) =>
              UserManagementService(context.read<ApiService>()),
        ),
        Provider<ReportService>(
          create: (context) => ReportService(context.read<ApiService>()),
        ),
        Provider<CustomerProfileService>(
          create: (context) =>
              CustomerProfileService(context.read<ApiService>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) =>
              AuthController(context.read<AuthService>())..restoreSession(),
        ),
      ],
      child: const PayGameApp(),
    ),
  );
}

class PayGameApp extends StatelessWidget {
  const PayGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PayGame',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator(color: AppColors.red)),
      );
    }

    if (!auth.isAuthenticated) {
      return const IndexView();
    }

    if (auth.isAdmin) {
      return const AdminHomePageView();
    }

    return const HomePageView();
  }
}
