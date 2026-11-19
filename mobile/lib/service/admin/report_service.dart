import 'package:mobile/core/api_constant.dart';
import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/api_service.dart';

/// Service boundary for admin report API calls.
/// It validates response shapes and maps JSON to immutable report models.
class ReportService {
  final ApiService api;
  ReportService(this.api);

  /// Loads all report sections in parallel for ReportView.
  Future<AdminReportModel> getAdminReport() async {
    final responses = await Future.wait([
      api.get(ApiConstant.adminReportsSummary),
      api.get(ApiConstant.adminReportsMonthlyRevenue),
      api.get(ApiConstant.adminReportsTopGames),
      api.get(ApiConstant.adminReportsOrderStatuses),
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
      _asStringMap(summaryResponse['summary']),
    );

    final monthlyRevenue = _parseListModels(
      revenueResponse['monthly_revenue'] as List,
      (item) => MonthlyRevenueModel.fromJson(_asStringMap(item)),
    );

    final topGames = _parseListModels(
      gamesResponse['top_games'] as List,
      (item) => TopGameModel.fromJson(_asStringMap(item)),
    );

    final orderStatuses = _parseListModels(
      statusesResponse['order_statuses'] as List,
      (item) => OrderStatusModel.fromJson(_asStringMap(item)),
    );

    return AdminReportModel(
      summary: summary,
      monthlyRevenue: monthlyRevenue,
      topGames: topGames,
      orderStatuses: orderStatuses,
    );
  }

  /// Loads only the summary section for the dashboard overview.
  Future<ReportSummary> getSummary() async {
    final response = await api.get(ApiConstant.adminReportsSummary);

    if (response is! Map || response['summary'] is! Map) {
      throw const FormatException('Invalid report summary response');
    }

    return ReportSummary.fromJson(_asStringMap(response['summary']));
  }

  Map<String, dynamic> _asStringMap(Object? value) {
    return Map<String, dynamic>.from(value as Map);
  }

  List<T> _parseListModels<T>(
    List<dynamic> items,
    T Function(Object? item) parser,
  ) {
    return items.map(parser).toList();
  }
}
