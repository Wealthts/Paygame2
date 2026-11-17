import '../../model/admin/admin_report_model.dart';
import '../api_service.dart';

class ReportService {
  final ApiService api;

  ReportService(this.api);

  Future<AdminReportModel> getAdminReport() async {
    final responses = await Future.wait([
      api.get('/api/admin/reports/summary'),
      api.get('/api/admin/reports/monthly-revenue'),
      api.get('/api/admin/reports/top-games'),
      api.get('/api/admin/reports/order-statuses'),
    ]);

    final summaryResponse = responses[0];
    final revenueResponse = responses[1];
    final gamesResponse = responses[2];
    final statusesResponse = responses[3];

    if (summaryResponse is! Map ||
        revenueResponse is! Map ||
        gamesResponse is! Map ||
        statusesResponse is! Map) {
      throw const FormatException('Invalid report response');
    }

    if (summaryResponse['summary'] is! Map ||
        revenueResponse['monthly_revenue'] is! List ||
        gamesResponse['top_games'] is! List ||
        statusesResponse['order_statuses'] is! List) {
      throw const FormatException('Report data is incomplete');
    }

    final summary = ReportSummary.fromJson(
      Map<String, dynamic>.from(summaryResponse['summary'] as Map),
    );

    final monthlyRevenue = (revenueResponse['monthly_revenue'] as List)
        .map(
          (item) => MonthlyRevenueModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final topGames = (gamesResponse['top_games'] as List)
        .map(
          (item) =>
              TopGameModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    final orderStatuses = (statusesResponse['order_statuses'] as List)
        .map(
          (item) =>
              OrderStatusModel.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    return AdminReportModel(
      summary: summary,
      monthlyRevenue: monthlyRevenue,
      topGames: topGames,
      orderStatuses: orderStatuses,
    );
  }

  // Get summary only for Admin Dashboard
  Future<ReportSummary> getSummary() async {
    final response = await api.get('/api/admin/reports/summary');

    if (response is! Map || response['summary'] is! Map) {
      throw const FormatException('Invalid report summary response');
    }

    return ReportSummary.fromJson(
      Map<String, dynamic>.from(response['summary'] as Map),
    );
  }
}
