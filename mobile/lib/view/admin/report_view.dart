import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/admin/report_controller.dart';
import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/service/admin/csv_export_service.dart';

/// Full admin report page.
/// Coordinates loading, filters, chart cards, refresh, and CSV export presentation.
class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportController controller;

  int _selectedRevenueMonths = 6;
  int _selectedTopGames = 5;
  String _selectedOrderStatus = 'all';

  @override
  void initState() {
    super.initState();

    controller = ReportController(context.read<ReportService>());
    controller.loadReport();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String _money(double value) {
    return '฿${value.toStringAsFixed(2)}';
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'สำเร็จ';
      case 'pending':
        return 'รอดำเนินการ';
      case 'cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  // --------------------------------------------------
  // Export CSV
  // --------------------------------------------------

  // CSV export: applies the current UI filters, builds rows, then delegates download.
  void _exportReport(AdminReportModel report) {
    final revenueStartIndex =
        report.monthlyRevenue.length > _selectedRevenueMonths
        ? report.monthlyRevenue.length - _selectedRevenueMonths
        : 0;

    final visibleRevenue = report.monthlyRevenue.sublist(revenueStartIndex);

    final visibleStatuses = _selectedOrderStatus == 'all'
        ? report.orderStatuses
        : report.orderStatuses
              .where(
                (item) => item.status.toLowerCase() == _selectedOrderStatus,
              )
              .toList();

    final visibleGames = report.topGames.take(_selectedTopGames).toList();

    final summary = report.summary;

    final rows = <List<Object?>>[
      ['PAYGAME - ADMIN REPORT'],
      ['Exported At', DateTime.now().toIso8601String()],
      [],
      ['SYSTEM SUMMARY'],
      ['Metric', 'Value'],
      ['Total Revenue (THB)', summary.totalRevenue],
      ['Total Orders', summary.totalOrders],
      ['Completed Orders', summary.completedOrders],
      ['Pending Orders', summary.pendingOrders],
      ['Cancelled Orders', summary.cancelledOrders],
      ['Paid Payments', summary.paidPaymentCount],
      ['Total Members', summary.totalMembers],
      [],
      ['MONTHLY REVENUE'],
      ['Month', 'Revenue (THB)', 'Payment Count'],
      ...visibleRevenue.map(
        (item) => <Object?>[item.month, item.revenue, item.paymentCount],
      ),
      [],
      ['ORDER STATUSES'],
      ['Status', 'Order Count'],
      ...visibleStatuses.map(
        (item) => <Object?>[_statusLabel(item.status), item.orderCount],
      ),
      [],
      ['TOP GAMES'],
      ['Rank', 'Game Name', 'Order Count', 'Completed Sales (THB)'],
      ...visibleGames.asMap().entries.map(
        (entry) => <Object?>[
          entry.key + 1,
          entry.value.gameName,
          entry.value.orderCount,
          entry.value.completedSales,
        ],
      ),
    ];

    final now = DateTime.now();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    final fileName =
        'paygame_report_${now.year}'
        '${twoDigits(now.month)}'
        '${twoDigits(now.day)}.csv';

    CsvExportService.download(fileName: fileName, rows: rows);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ส่งออกรายงาน CSV เรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // --------------------------------------------------
  // Summary
  // --------------------------------------------------

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? description,
  }) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 26),
                  const Spacer(),
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSummary(ReportSummary summary) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _metricCard(
          title: 'รายได้รวม',
          value: _money(summary.totalRevenue),
          icon: Icons.account_balance_wallet,
          color: Colors.green,
          description: 'นับเฉพาะ Payment ที่ Paid',
        ),
        _metricCard(
          title: 'คำสั่งซื้อทั้งหมด',
          value: summary.totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.blue,
        ),
        _metricCard(
          title: 'คำสั่งซื้อสำเร็จ',
          value: summary.completedOrders.toString(),
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _metricCard(
          title: 'รอดำเนินการ',
          value: summary.pendingOrders.toString(),
          icon: Icons.pending_actions,
          color: Colors.orange,
        ),
        _metricCard(
          title: 'ยกเลิก',
          value: summary.cancelledOrders.toString(),
          icon: Icons.cancel,
          color: Colors.red,
        ),
        _metricCard(
          title: 'สมาชิกทั้งหมด',
          value: summary.totalMembers.toString(),
          icon: Icons.people,
          color: Colors.indigo,
        ),
      ],
    );
  }

  // --------------------------------------------------
  // Revenue Filter
  // --------------------------------------------------

  Widget _buildRevenueFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกช่วงเวลาที่ต้องการดู',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('3 เดือนล่าสุด'),
                  selected: _selectedRevenueMonths == 3,
                  onSelected: (_) {
                    setState(() {
                      _selectedRevenueMonths = 3;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('6 เดือนล่าสุด'),
                  selected: _selectedRevenueMonths == 6,
                  onSelected: (_) {
                    setState(() {
                      _selectedRevenueMonths = 6;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyRevenue(List<MonthlyRevenueModel> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('ยังไม่มีข้อมูลรายได้ในช่วงเวลานี้')),
        ),
      );
    }

    final startIndex = data.length > _selectedRevenueMonths
        ? data.length - _selectedRevenueMonths
        : 0;

    final visibleData = data.sublist(startIndex);

    final maxRevenue = visibleData.fold<double>(
      0,
      (previous, item) => item.revenue > previous ? item.revenue : previous,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'รายได้จากการชำระเงินสำเร็จ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: visibleData.map((item) {
                  final barHeight = maxRevenue <= 0
                      ? 0.0
                      : (item.revenue / maxRevenue) * 115;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            item.revenue >= 1000
                                ? '${(item.revenue / 1000).toStringAsFixed(1)}k'
                                : item.revenue.toStringAsFixed(0),
                            style: const TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: double.infinity,
                            height: barHeight == 0 ? 2 : barHeight,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.month,
                            style: const TextStyle(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${item.paymentCount} รายการ',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Order Status Filter
  // --------------------------------------------------

  Widget _buildOrderStatusFilter() {
    final filters = [
      {'value': 'all', 'label': 'ทั้งหมด'},
      {'value': 'completed', 'label': 'สำเร็จ'},
      {'value': 'pending', 'label': 'รอดำเนินการ'},
      {'value': 'cancelled', 'label': 'ยกเลิก'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกสถานะคำสั่งซื้อ',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                final value = filter['value']!;

                return ChoiceChip(
                  label: Text(filter['label']!),
                  selected: _selectedOrderStatus == value,
                  onSelected: (_) {
                    setState(() {
                      _selectedOrderStatus = value;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatuses(List<OrderStatusModel> statuses, int totalOrders) {
    final visibleStatuses = _selectedOrderStatus == 'all'
        ? statuses
        : statuses
              .where(
                (item) => item.status.toLowerCase() == _selectedOrderStatus,
              )
              .toList();

    if (visibleStatuses.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('ไม่มีข้อมูลสำหรับสถานะที่เลือก')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: visibleStatuses.map((item) {
            final color = _statusColor(item.status);

            final progress = totalOrders <= 0
                ? 0.0
                : item.orderCount / totalOrders;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusLabel(item.status),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text('${item.orderCount} รายการ'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Top Games
  // --------------------------------------------------

  Widget _buildTopGamesFilter() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'จำนวนอันดับที่ต้องการแสดง',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('3 อันดับ'),
                  selected: _selectedTopGames == 3,
                  onSelected: (_) {
                    setState(() {
                      _selectedTopGames = 3;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('5 อันดับ'),
                  selected: _selectedTopGames == 5,
                  onSelected: (_) {
                    setState(() {
                      _selectedTopGames = 5;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGames(List<TopGameModel> games) {
    final visibleGames = games.take(_selectedTopGames).toList();

    if (visibleGames.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('ยังไม่มีข้อมูลเกม')),
        ),
      );
    }

    final maxOrders = visibleGames.fold<int>(
      0,
      (previous, item) =>
          item.orderCount > previous ? item.orderCount : previous,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: visibleGames.asMap().entries.map((entry) {
            final index = entry.key;
            final game = entry.value;

            final progress = maxOrders <= 0 ? 0.0 : game.orderCount / maxOrders;

            return Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(radius: 15, child: Text('${index + 1}')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          game.gameName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text('${game.orderCount} ออเดอร์'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 8,
                    color: Colors.indigo,
                    backgroundColor: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'ยอดคำสั่งซื้อที่สำเร็จ: '
                    '${_money(game.completedSales)}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --------------------------------------------------
  // Report Content
  // --------------------------------------------------

  Widget _buildReport(AdminReportModel report) {
    return RefreshIndicator(
      onRefresh: controller.loadReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          const Text(
            'ภาพรวมของระบบ PayGame',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'ข้อมูลสรุปจากคำสั่งซื้อ การชำระเงิน และสมาชิก',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          _buildSummary(report.summary),

          _sectionTitle('รายได้ย้อนหลัง $_selectedRevenueMonths เดือน'),
          _buildRevenueFilter(),
          const SizedBox(height: 8),
          _buildMonthlyRevenue(report.monthlyRevenue),

          _sectionTitle('คำสั่งซื้อแยกตามสถานะ'),
          _buildOrderStatusFilter(),
          const SizedBox(height: 8),
          _buildOrderStatuses(report.orderStatuses, report.summary.totalOrders),

          _sectionTitle('เกมยอดนิยม $_selectedTopGames อันดับ'),
          _buildTopGamesFilter(),
          const SizedBox(height: 8),
          _buildTopGames(report.topGames),

          const SizedBox(height: 12),
          const Text(
            'หมายเหตุ: ตัวกรองมีผลต่อการแสดงผลบนหน้านี้เท่านั้น '
            'ไม่ได้เปลี่ยนแปลงข้อมูลที่บันทึกในระบบ',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // Main Build
  // --------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานและสถิติ'),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final report = controller.report;

              return IconButton(
                tooltip: 'ส่งออกรายงาน CSV',
                onPressed: report == null || controller.isLoading
                    ? null
                    : () => _exportReport(report),
                icon: const Icon(Icons.download),
              );
            },
          ),
          IconButton(
            tooltip: 'รีเฟรชรายงาน',
            onPressed: controller.isLoading ? null : controller.loadReport,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.report == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage != null && controller.report == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(controller.errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: controller.loadReport,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final report = controller.report;

          if (report == null) {
            return const Center(child: Text('ไม่พบข้อมูลรายงาน'));
          }

          return Column(
            children: [
              if (controller.isLoading) const LinearProgressIndicator(),

              if (controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'รีเฟรชข้อมูลไม่สำเร็จ: '
                    '${controller.errorMessage}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              Expanded(child: _buildReport(report)),
            ],
          );
        },
      ),
    );
  }
}
