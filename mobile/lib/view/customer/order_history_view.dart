import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/view/customer/order_details_view.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  // ========================================
  // Load Orders
  // ========================================
  void _loadOrders() {
    _ordersFuture = context.read<OrderService>().getMyOrders();
  }

  // ========================================
  // Refresh Orders
  // ========================================
  Future<void> _refreshOrders() async {
    final future = context.read<OrderService>().getMyOrders();

    setState(() {
      _ordersFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder จะแสดงข้อผิดพลาด
    }
  }

  // ========================================
  // Retry
  // ========================================
  void _retryLoading() {
    setState(_loadOrders);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('รายการสั่งซื้อของฉัน'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            // Loading
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.red),
                    SizedBox(height: 16),
                    Text(
                      'กำลังโหลดประวัติคำสั่งซื้อ...',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError) {
              return _buildError();
            }

            final orders = snapshot.data ?? [];

            // Empty
            if (orders.isEmpty) {
              return _buildEmpty();
            }

            // Success
            return RefreshIndicator(
              onRefresh: _refreshOrders,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummary(orders),

                  const SizedBox(height: 22),

                  const Text(
                    'คำสั่งซื้อทั้งหมด',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerOrderDetailsView(order: order),
                            ),
                          );

                          if (result == true && mounted) {
                            await _refreshOrders();
                          }
                        },
                        child: _OrderCard(order: order),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'ดึงข้อมูลล่าสุดจากระบบ PayGame',
                      style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================
  // Summary
  // ========================================
  Widget _buildSummary(List<OrderModel> orders) {
    final pending = orders.where((order) => order.status == 'Pending').length;

    final processing = orders
        .where((order) => order.status == 'Processing')
        .length;

    final completed = orders
        .where((order) => order.status == 'Completed')
        .length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.redDark, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สรุปคำสั่งซื้อ',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _summaryItem(
                'ทั้งหมด',
                orders.length.toString(),
                Icons.receipt_long,
              ),

              const SizedBox(width: 24),

              _summaryItem(
                'รอดำเนินการ',
                pending.toString(),
                Icons.hourglass_top,
              ),

              const SizedBox(width: 24),

              _summaryItem('กำลังเติมเกม', processing.toString(), Icons.sync),

              const SizedBox(width: 24),

              _summaryItem(
                'สำเร็จ',
                completed.toString(),
                Icons.check_circle_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldLight, size: 20),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Error
  // ========================================
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.inkMuted, size: 60),

            const SizedBox(height: 16),

            const Text(
              'ไม่สามารถโหลดประวัติคำสั่งซื้อได้',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Empty
  // ========================================
  Widget _buildEmpty() {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 110),

          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.inkMuted,
            size: 72,
          ),

          SizedBox(height: 18),

          Text(
            'ยังไม่มีคำสั่งซื้อ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'เมื่อคุณสร้างคำสั่งซื้อ รายการจะแสดงที่หน้านี้',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ORDER CARD
// ==========================================
class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(order.status);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order #${order.orderId}',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Divider(color: AppColors.divider, height: 26),

          // Game
          _detailRow(Icons.sports_esports, 'เกม', order.gameName),

          const SizedBox(height: 12),

          // Package
          _detailRow(Icons.diamond_outlined, 'แพ็กเกจ', order.packageName),

          const SizedBox(height: 12),

          // UID
          _detailRow(Icons.person_outline, 'Player UID', order.playerUid),

          if (order.serverCode.isNotEmpty) ...[
            const SizedBox(height: 12),

            _detailRow(Icons.dns_outlined, 'Server ID', order.serverCode),
          ],

          const SizedBox(height: 12),

          _detailRow(
            Icons.calendar_today_outlined,
            'วันที่สั่งซื้อ',
            _formatDate(order.createdAt),
          ),

          const Divider(color: AppColors.divider, height: 26),

          // Price
          _priceRow('ราคาแพ็กเกจ', order.originalPrice),

          if (order.discountAmount > 0) ...[
            const SizedBox(height: 9),

            _priceRow(
              'ส่วนลดรวม',
              -order.discountAmount,
              valueColor: AppColors.success,
            ),
          ],

          const Divider(color: AppColors.divider, height: 26),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดสุทธิ',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                '฿${order.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.goldText,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Detail Row
  // ========================================
  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.inkMuted),

        const SizedBox(width: 9),

        SizedBox(
          width: 95,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),

        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // Price Row
  // ========================================
  Widget _priceRow(
    String label,
    double amount, {
    Color valueColor = AppColors.inkMuted,
  }) {
    final isNegative = amount < 0;
    final displayAmount = amount.abs();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
        ),

        Text(
          '${isNegative ? '-' : ''}'
          '฿${displayAmount.toStringAsFixed(2)}',
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ========================================
  // Status Color
  // ========================================
  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'Cancelled':
        return Colors.redAccent;
      case 'Pending':
        return AppColors.gold;
      case 'Processing':
        return AppColors.red;
      default:
        return AppColors.inkMuted;
    }
  }

  // ========================================
  // Status Label
  // ========================================
  String _statusLabel(String status) {
    switch (status) {
      case 'Completed':
        return 'สำเร็จ';
      case 'Cancelled':
        return 'ยกเลิก';
      case 'Pending':
        return 'รอดำเนินการ';
      case 'Processing':
        return 'กำลังดำเนินการ';
      default:
        return status;
    }
  }

  // ========================================
  // Date Format
  // ========================================
  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final value = date.toLocal();

    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();

    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}
