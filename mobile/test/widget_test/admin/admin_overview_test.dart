import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/view/admin/admin_overview_view.dart';
import 'package:mobile/view/admin/report_view.dart';

import '../../support/fake_services.dart';
import '../../support/theme_widget_test_helper.dart';

Future<void> _pumpOverview(
  WidgetTester tester,
  FakeReportService service,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<ReportService>.value(
      value: service,
      child: const MaterialApp(home: Scaffold(body: AdminOverviewSection())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testPayGameThemeContract('Admin overview');

  testWidgets('shows summary metrics and operational status', (tester) async {
    final service = FakeReportService();
    await _pumpOverview(tester, service);

    expect(find.text('ภาพรวมระบบ PayGame'), findsOneWidget);
    expect(find.text('฿1200.50'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('7 รายการ'), findsOneWidget);
    expect(find.text('จำนวนรายการที่ชำระสำเร็จ'), findsOneWidget);
    expect(service.summaryCalls, 1);
  });

  testWidgets('shows an error and retries the summary request', (tester) async {
    final service = FakeReportService()
      ..summaryError = const ApiException(
        statusCode: 503,
        message: 'summary unavailable',
      );
    await _pumpOverview(tester, service);

    expect(find.text('summary unavailable'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    service.summaryError = null;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('ภาพรวมระบบ PayGame'), findsOneWidget);
    expect(service.summaryCalls, 2);
  });

  testWidgets('opens the full report from the overview', (tester) async {
    final service = FakeReportService();
    await _pumpOverview(tester, service);

    await tester.tap(find.text('ดูรายงานและสถิติทั้งหมด'));
    await tester.pumpAndSettle();

    expect(find.byType(ReportView), findsOneWidget);
    expect(find.text('รายงานและสถิติ'), findsOneWidget);
    expect(service.reportCalls, 1);
  });
}
