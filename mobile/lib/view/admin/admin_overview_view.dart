import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/admin/report_service.dart';
import 'package:mobile/view/admin/report_view.dart';

/// Dashboard summary section.
/// Fetches only ReportSummary and provides a future-based loading/error/refresh state.
class AdminOverviewSection extends StatefulWidget {
  const AdminOverviewSection({super.key});

  @override
  State<AdminOverviewSection> createState() => _AdminOverviewSectionState();
}

class _AdminOverviewSectionState extends State<AdminOverviewSection> {
  late final ReportService reportService;
  late Future<ReportSummary> summaryFuture;

  @override
  void initState() {
    super.initState();

    reportService = context.read<ReportService>();
    summaryFuture = reportService.getSummary();
  }

  /// Replaces the FutureBuilder future and makes the refresh button/load state explicit.
  Future<void> refreshSummary() async {
    final future = reportService.getSummary();

    setState(() {
      summaryFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder will show the error state.
    }
  }

  String money(double value) {
    return '฿${value.toStringAsFixed(2)}';
  }

  Widget metricCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
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
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOverview(ReportSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ภาพรวมระบบ PayGame',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'สรุปข้อมูลสำคัญของระบบ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: refreshSummary,
              tooltip: 'รีเฟรชข้อมูล',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            metricCard(
              title: 'รายได้สะสม',
              value: money(summary.totalRevenue),
              description: 'เฉพาะ Payment ที่ Paid',
              icon: Icons.account_balance_wallet,
              color: Colors.green,
            ),
            metricCard(
              title: 'ออเดอร์ทั้งหมด',
              value: summary.totalOrders.toString(),
              description: 'จำนวนคำสั่งซื้อทุกสถานะ',
              icon: Icons.shopping_cart,
              color: Colors.blue,
            ),
            metricCard(
              title: 'รอดำเนินการ',
              value: summary.pendingOrders.toString(),
              description: 'Pending Orders',
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            metricCard(
              title: 'สมาชิกทั้งหมด',
              value: summary.totalMembers.toString(),
              description: 'บัญชีที่มี role เป็น user',
              icon: Icons.people,
              color: Colors.indigo,
            ),
          ],
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สถานะการดำเนินงาน',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _statusItem(
                        'สำเร็จ',
                        summary.completedOrders,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _statusItem(
                        'รอดำเนินการ',
                        summary.pendingOrders,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _statusItem(
                        'ยกเลิก',
                        summary.cancelledOrders,
                        Colors.red,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 28),

                Row(
                  children: [
                    const Icon(Icons.payments_outlined, color: Colors.green),
                    const SizedBox(width: 10),
                    const Expanded(child: Text('จำนวนรายการที่ชำระสำเร็จ')),
                    Text(
                      '${summary.paidPaymentCount} รายการ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReportView()),
              );
            },
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('ดูรายงานและสถิติทั้งหมด'),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  Widget _statusItem(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReportSummary>(
      future: summaryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.cloud_off, size: 36, color: Colors.orange),
                  const SizedBox(height: 8),
                  const Text(
                    'ไม่สามารถโหลดข้อมูลภาพรวมได้',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: refreshSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            ),
          );
        }

        final summary = snapshot.data;
        if (summary == null) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            if (snapshot.connectionState == ConnectionState.waiting)
              const LinearProgressIndicator(),
            buildOverview(summary),
          ],
        );
      },
    );
  }
}
