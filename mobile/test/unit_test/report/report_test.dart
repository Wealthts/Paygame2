import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/admin/admin_report_model.dart';

void main() {
  group('Admin report models', () {
    test('parses summary fields from numeric and string values', () {
      final summary = ReportSummary.fromJson({
        'total_orders': '12',
        'pending_orders': 2,
        'completed_orders': '8',
        'cancelled_orders': 2,
        'paid_payment_count': '8',
        'total_revenue': '1272.50',
        'total_members': 5,
      });

      expect(summary.totalOrders, 12);
      expect(summary.pendingOrders, 2);
      expect(summary.completedOrders, 8);
      expect(summary.cancelledOrders, 2);
      expect(summary.paidPaymentCount, 8);
      expect(summary.totalRevenue, 1272.5);
      expect(summary.totalMembers, 5);
    });

    test('uses zero defaults for omitted summary values', () {
      final summary = ReportSummary.fromJson({});

      expect(summary.totalOrders, 0);
      expect(summary.totalRevenue, 0);
      expect(summary.totalMembers, 0);
    });

    test('parses monthly revenue, top games, and order statuses', () {
      final revenue = MonthlyRevenueModel.fromJson({
        'month': 202601,
        'revenue': '450.75',
        'payment_count': '3',
      });
      final game = TopGameModel.fromJson({
        'game_name': 'Arena Test',
        'order_count': '7',
        'completed_sales': '900.50',
      });
      final status = OrderStatusModel.fromJson({
        'status': 'Completed',
        'order_count': '8',
      });

      expect(revenue.month, '202601');
      expect(revenue.revenue, 450.75);
      expect(revenue.paymentCount, 3);
      expect(game.gameName, 'Arena Test');
      expect(game.orderCount, 7);
      expect(game.completedSales, 900.5);
      expect(status.status, 'Completed');
      expect(status.orderCount, 8);
    });

    test('rejects invalid numeric values', () {
      expect(
        () => ReportSummary.fromJson({'total_orders': 'many'}),
        throwsFormatException,
      );
    });
  });
}
