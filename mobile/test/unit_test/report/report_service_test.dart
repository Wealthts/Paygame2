import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api_constant.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/api_service.dart';

// Mock API boundary: no HTTP/network calls; records requested report endpoints.
class _MockApiService extends ApiService {
  _MockApiService(this.responses);

  final Map<String, Object?> responses;
  final requests = <String>[];

  @override
  Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    requests.add(path);
    final response = responses[path];
    if (response is Exception) throw response;
    return response;
  }
}

Map<String, Object?> _reportResponses() => {
  ApiConstant.adminReportsSummary: {
    'summary': {
      'total_orders': '12',
      'pending_orders': 2,
      'completed_orders': 8,
      'cancelled_orders': 2,
      'paid_payment_count': 8,
      'total_revenue': '1272.50',
      'total_members': 5,
    },
  },
  ApiConstant.adminReportsMonthlyRevenue: {
    'monthly_revenue': [
      {'month': '2026-01', 'revenue': '500.50', 'payment_count': '3'},
    ],
  },
  ApiConstant.adminReportsTopGames: {
    'top_games': [
      {'game_name': 'Arena Test', 'order_count': '7', 'completed_sales': 900.5},
    ],
  },
  ApiConstant.adminReportsOrderStatuses: {
    'order_statuses': [
      {'status': 'Completed', 'order_count': '8'},
    ],
  },
};

// Service tests: verify endpoint composition, response validation, and JSON mapping.
void main() {
  group('ReportService', () {
    test('loads and parses all report sections', () async {
      final api = _MockApiService(_reportResponses());

      final report = await ReportService(api).getAdminReport();

      expect(report.summary.totalOrders, 12);
      expect(report.summary.totalRevenue, 1272.5);
      expect(report.monthlyRevenue.single.month, '2026-01');
      expect(report.monthlyRevenue.single.paymentCount, 3);
      expect(report.topGames.single.gameName, 'Arena Test');
      expect(report.topGames.single.completedSales, 900.5);
      expect(report.orderStatuses.single.status, 'Completed');
      expect(report.orderStatuses.single.orderCount, 8);
      expect(api.requests, [
        ApiConstant.adminReportsSummary,
        ApiConstant.adminReportsMonthlyRevenue,
        ApiConstant.adminReportsTopGames,
        ApiConstant.adminReportsOrderStatuses,
      ]);
    });

    test('rejects a response with an invalid section shape', () async {
      final responses = _reportResponses()
        ..[ApiConstant.adminReportsTopGames] = {'top_games': null};

      expect(
        ReportService(_MockApiService(responses)).getAdminReport(),
        throwsFormatException,
      );
    });

    test('loads dashboard summary without requesting report details', () async {
      final api = _MockApiService(_reportResponses());

      final summary = await ReportService(api).getSummary();

      expect(summary.pendingOrders, 2);
      expect(summary.paidPaymentCount, 8);
      expect(api.requests, [ApiConstant.adminReportsSummary]);
    });

    test('rejects a malformed dashboard summary', () async {
      final api = _MockApiService({
        ApiConstant.adminReportsSummary: {'summary': []},
      });

      expect(ReportService(api).getSummary(), throwsFormatException);
    });
  });
}
