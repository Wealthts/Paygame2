import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/api_service.dart';

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
  '/api/admin/reports/summary': {
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
  '/api/admin/reports/monthly-revenue': {
    'monthly_revenue': [
      {'month': '2026-01', 'revenue': '500.50', 'payment_count': '3'},
    ],
  },
  '/api/admin/reports/top-games': {
    'top_games': [
      {'game_name': 'Arena Test', 'order_count': '7', 'completed_sales': 900.5},
    ],
  },
  '/api/admin/reports/order-statuses': {
    'order_statuses': [
      {'status': 'Completed', 'order_count': '8'},
    ],
  },
};

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
        '/api/admin/reports/summary',
        '/api/admin/reports/monthly-revenue',
        '/api/admin/reports/top-games',
        '/api/admin/reports/order-statuses',
      ]);
    });

    test('rejects a response with an invalid section shape', () async {
      final responses = _reportResponses()
        ..['/api/admin/reports/top-games'] = {'top_games': null};

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
      expect(api.requests, ['/api/admin/reports/summary']);
    });

    test('rejects a malformed dashboard summary', () async {
      final api = _MockApiService({
        '/api/admin/reports/summary': {'summary': []},
      });

      expect(ReportService(api).getSummary(), throwsFormatException);
    });
  });
}
