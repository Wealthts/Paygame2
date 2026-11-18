import '../../support/theme_widget_test_helper.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/auth_controller.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/view/admin/admin_overview_view.dart';
import 'package:mobile/view/admin/homepage_view.dart';
import 'package:mobile/view/admin/report_view.dart';

import '../../support/fake_services.dart';

Future<AuthController> _signedInAdmin() async {
  final controller = AuthController(FakeAuthService());
  await controller.login(username: 'admin', password: 'password');
  return controller;
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  FakeReportService reportService,
  AuthController authController,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        Provider<ReportService>.value(value: reportService),
      ],
      child: const MaterialApp(home: AdminHomePageView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testPayGameThemeContract('Admin dashboard');

  testWidgets('shows the signed-in admin dashboard and overview', (
    tester,
  ) async {
    final reportService = FakeReportService();
    final authController = await _signedInAdmin();
    await _pumpDashboard(tester, reportService, authController);

    expect(find.text('PAYGAME ADMIN'), findsOneWidget);
    expect(find.text('ยินดีต้อนรับ Test Player'), findsOneWidget);
    expect(find.byType(AdminOverviewSection), findsOneWidget);
    expect(find.text('Reports & Analytics'), findsOneWidget);
    expect(find.text('ภาพรวมระบบ PayGame'), findsOneWidget);
    expect(reportService.summaryCalls, 1);
  });

  testWidgets('opens reports from the dashboard menu', (tester) async {
    final reportService = FakeReportService();
    final authController = await _signedInAdmin();
    await _pumpDashboard(tester, reportService, authController);

    await tester.tap(find.text('Reports & Analytics'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportView), findsOneWidget);
    expect(find.text('รายงานและสถิติ'), findsOneWidget);
    expect(reportService.reportCalls, 1);
  });

  testWidgets('logout returns the dashboard greeting to its default', (
    tester,
  ) async {
    final authController = await _signedInAdmin();
    await _pumpDashboard(tester, FakeReportService(), authController);

    await tester.tap(find.byTooltip('Logout'));
    await tester.pumpAndSettle();

    expect(find.text('ยินดีต้อนรับ Admin'), findsOneWidget);
    expect(authController.isAuthenticated, isFalse);
  });
}
