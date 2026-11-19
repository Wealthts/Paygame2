import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/admin/report_controller.dart';
import 'package:mobile/service/api_service.dart';

import '../../support/fake_services.dart';

// Controller tests: verify presentation state, listener transitions, and recovery.
// Network data is supplied by FakeReportService from test/support.
void main() {
  group('ReportController', () {
    test('loads report and notifies listeners around the request', () async {
      final service = FakeReportService();
      final controller = ReportController(service);
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.loadReport();

      expect(controller.report, testAdminReport);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(service.reportCalls, 1);
      expect(loadingStates, [true, false]);
      controller.dispose();
    });

    test('stores the service error and can recover on a later load', () async {
      final service = FakeReportService()
        ..reportError = const ApiException(
          statusCode: 503,
          message: 'report unavailable',
        );
      final controller = ReportController(service);

      await controller.loadReport();

      expect(controller.report, isNull);
      expect(controller.errorMessage, 'report unavailable');
      expect(controller.isLoading, isFalse);

      service.reportError = null;
      await controller.loadReport();

      expect(controller.report, testAdminReport);
      expect(controller.errorMessage, isNull);
      expect(service.reportCalls, 2);
      controller.dispose();
    });
  });
}
