import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../model/payment_model.dart';
import '../../service/payment_service.dart';

class PaymentHistoryView extends StatefulWidget {
  const PaymentHistoryView({super.key});

  @override
  State<PaymentHistoryView> createState() => _PaymentHistoryViewState();
}

class _PaymentHistoryViewState extends State<PaymentHistoryView> {
  late Future<List<PaymentModel>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ========================================
  // Load Payments
  // ========================================
  void _loadPayments() {
    _paymentsFuture = context.read<PaymentService>().getMyPayments();
  }

  // ========================================
  // Refresh Payments
  // ========================================
  Future<void> _refreshPayments() async {
    final future = context.read<PaymentService>().getMyPayments();

    setState(() {
      _paymentsFuture = future;
    });

    try {
      await future;
    } catch (_) {
      // FutureBuilder แสดง Error ให้เอง
    }
  }

  // ========================================
  // Retry
  // ========================================
  void _retryLoading() {
    setState(_loadPayments);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('ประวัติการชำระเงิน'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<PaymentModel>>(
          future: _paymentsFuture,
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
                      'กำลังโหลดประวัติการชำระเงิน...',
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

            final payments = snapshot.data ?? [];

            // Empty
            if (payments.isEmpty) {
              return _buildEmpty();
            }

            // Success
            return RefreshIndicator(
              onRefresh: _refreshPayments,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummary(payments),

                  const SizedBox(height: 22),

                  const Text(
                    'รายการชำระเงินทั้งหมด',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  ...payments.map(
                    (payment) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _PaymentCard(payment: payment),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'ข้อมูลจากระบบ PayGame',
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
  Widget _buildSummary(List<PaymentModel> payments) {
    final pending = payments
        .where((payment) => payment.status == 'Pending')
        .length;

    final paid = payments.where((payment) => payment.status == 'Paid').length;

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
            'สรุปการชำระเงิน',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              _summaryItem(
                'ทั้งหมด',
                payments.length.toString(),
                Icons.receipt_long,
              ),

              const SizedBox(width: 22),

              _summaryItem(
                'รอตรวจสอบ',
                pending.toString(),
                Icons.hourglass_top,
              ),

              const SizedBox(width: 22),

              _summaryItem(
                'ชำระแล้ว',
                paid.toString(),
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
              'ไม่สามารถโหลดประวัติการชำระเงินได้',
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
      onRefresh: _refreshPayments,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 110),

          Icon(Icons.payment_outlined, color: AppColors.inkMuted, size: 72),

          SizedBox(height: 18),

          Text(
            'ยังไม่มีประวัติการชำระเงิน',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 8),

          Text(
            'เมื่อคุณสร้างรายการชำระเงิน '
            'รายการจะแสดงที่หน้านี้',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// PAYMENT CARD
// ==========================================
class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;

  const _PaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(payment.status);

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
          // Payment ID and Status
          Row(
            children: [
              Expanded(
                child: Text(
                  'Payment #${payment.paymentId}',
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
                  _statusLabel(payment.status),
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

          _detailRow(
            Icons.receipt_long_outlined,
            'Order ID',
            '#${payment.orderId}',
          ),

          if (payment.gameName != null && payment.gameName!.isNotEmpty) ...[
            const SizedBox(height: 12),

            _detailRow(Icons.sports_esports_outlined, 'เกม', payment.gameName!),
          ],

          if (payment.packageName != null &&
              payment.packageName!.isNotEmpty) ...[
            const SizedBox(height: 12),

            _detailRow(Icons.diamond_outlined, 'แพ็กเกจ', payment.packageName!),
          ],

          const SizedBox(height: 12),

          _detailRow(Icons.account_balance_outlined, 'ช่องทาง', payment.method),

          const SizedBox(height: 12),

          _detailRow(Icons.tag, 'เลขอ้างอิง', payment.transactionRef),

          const SizedBox(height: 12),

          _detailRow(
            Icons.calendar_today_outlined,
            'วันที่แจ้ง',
            _formatDate(payment.createdAt),
          ),

          if (payment.paidAt != null) ...[
            const SizedBox(height: 12),

            _detailRow(
              Icons.check_circle_outline,
              'วันที่ชำระสำเร็จ',
              _formatDate(payment.paidAt),
            ),
          ],

          const Divider(color: AppColors.divider, height: 26),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ยอดชำระ',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                '฿${payment.amount.toStringAsFixed(2)}',
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
          width: 100,
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
  // Status Color
  // ========================================
  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
        return AppColors.success;

      case 'Pending':
        return AppColors.gold;

      default:
        return AppColors.inkMuted;
    }
  }

  // ========================================
  // Status Label
  // ========================================
  String _statusLabel(String status) {
    switch (status) {
      case 'Paid':
        return 'ชำระแล้ว';

      case 'Pending':
        return 'รอตรวจสอบ';

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
