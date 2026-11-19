/// Typed Mobile representation of the /reports/summary response.
/// fromJson converts the server's string or number values into stable Dart types.
class ReportSummary {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final int cancelledOrders;
  final int paidPaymentCount;
  final double totalRevenue;
  final int totalMembers;

  const ReportSummary({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.paidPaymentCount,
    required this.totalRevenue,
    required this.totalMembers,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalOrders: int.parse((json['total_orders'] ?? 0).toString()),
      pendingOrders: int.parse((json['pending_orders'] ?? 0).toString()),
      completedOrders: int.parse((json['completed_orders'] ?? 0).toString()),
      cancelledOrders: int.parse((json['cancelled_orders'] ?? 0).toString()),
      paidPaymentCount: int.parse((json['paid_payment_count'] ?? 0).toString()),
      totalRevenue: double.parse((json['total_revenue'] ?? 0).toString()),
      totalMembers: int.parse((json['total_members'] ?? 0).toString()),
    );
  }
}

/// One month of completed-payment revenue and payment count.
class MonthlyRevenueModel {
  final String month;
  final double revenue;
  final int paymentCount;

  const MonthlyRevenueModel({
    required this.month,
    required this.revenue,
    required this.paymentCount,
  });

  factory MonthlyRevenueModel.fromJson(Map<String, dynamic> json) {
    return MonthlyRevenueModel(
      month: json['month']?.toString() ?? '',
      revenue: double.parse((json['revenue'] ?? 0).toString()),
      paymentCount: int.parse((json['payment_count'] ?? 0).toString()),
    );
  }
}

/// One row from the server's top-games ranking.
class TopGameModel {
  final String gameName;
  final int orderCount;
  final double completedSales;

  const TopGameModel({
    required this.gameName,
    required this.orderCount,
    required this.completedSales,
  });

  factory TopGameModel.fromJson(Map<String, dynamic> json) {
    return TopGameModel(
      gameName: json['game_name']?.toString() ?? '',
      orderCount: int.parse((json['order_count'] ?? 0).toString()),
      completedSales: double.parse((json['completed_sales'] ?? 0).toString()),
    );
  }
}

/// One order-status group and its total count.
class OrderStatusModel {
  final String status;
  final int orderCount;

  const OrderStatusModel({required this.status, required this.orderCount});

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      status: json['status']?.toString() ?? '',
      orderCount: int.parse((json['order_count'] ?? 0).toString()),
    );
  }
}

/// Aggregate report model returned to the full ReportView.
/// It combines summary, monthly, game, and status API sections.
class AdminReportModel {
  final ReportSummary summary;
  final List<MonthlyRevenueModel> monthlyRevenue;
  final List<TopGameModel> topGames;
  final List<OrderStatusModel> orderStatuses;

  const AdminReportModel({
    required this.summary,
    required this.monthlyRevenue,
    required this.topGames,
    required this.orderStatuses,
  });
}
