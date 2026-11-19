import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/view/admin/report_view.dart';

import '../../support/fake_services.dart';
import '../../support/theme_widget_test_helper.dart';

// Widget setup: supplies the report service through Provider and a tall test viewport.
Future<void> _pumpReport(WidgetTester tester, FakeReportService service) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    Provider<ReportService>.value(
      value: service,
      child: const MaterialApp(home: ReportView()),
    ),
  );
  await tester.pumpAndSettle();
}

// Report widget contract: content rendering, status filtering, and retry behavior.
void main() {
  testPayGameThemeContract('Admin reports');

  testWidgets('renders report summary, revenue, statuses, and top games', (
    tester,
  ) async {
    final service = FakeReportService();
    await _pumpReport(tester, service);

    expect(find.text('รายงานและสถิติ'), findsOneWidget);
    expect(find.text('ภาพรวมของระบบ PayGame'), findsOneWidget);
    expect(find.text('฿1200.50'), findsOneWidget);
    expect(find.text('2026-01'), findsOneWidget);
    expect(find.text('Arena Test'), findsOneWidget);
    expect(find.text('รายได้ย้อนหลัง 6 เดือน'), findsOneWidget);
    expect(service.reportCalls, 1);
  });

  testWidgets('filters order status and updates the visible status rows', (
    tester,
  ) async {
    await _pumpReport(tester, FakeReportService());

    expect(find.text('สำเร็จ'), findsNWidgets(2));
    await tester.tap(find.widgetWithText(ChoiceChip, 'ยกเลิก'));
    await tester.pumpAndSettle();

    expect(find.text('สำเร็จ'), findsOneWidget);
    expect(find.text('ยกเลิก'), findsNWidgets(3));
    expect(find.text('ไม่มีข้อมูลสำหรับสถานะที่เลือก'), findsNothing);
  });

  testWidgets('shows a loading error and can retry', (tester) async {
    final service = FakeReportService()
      ..reportError = const ApiException(
        statusCode: 503,
        message: 'report unavailable',
      );
    await _pumpReport(tester, service);

    expect(find.text('report unavailable'), findsOneWidget);
    expect(find.text('ลองอีกครั้ง'), findsOneWidget);

    service.reportError = null;
    await tester.tap(find.text('ลองอีกครั้ง'));
    await tester.pumpAndSettle();

    expect(find.text('ภาพรวมของระบบ PayGame'), findsOneWidget);
    expect(service.reportCalls, 2);
  });
}
