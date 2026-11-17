import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';

class CustomerOrderDetailsView extends StatelessWidget {
  final OrderModel order;

  String _paymentStatusLabel(String? status) {
    switch (status) {
      case 'Pending':
        return 'รอชำระเงิน';
      case 'Paid':
        return 'ชำระเงินแล้ว';
      case 'Cancelled':
        return 'การชำระเงินถูกยกเลิก';
      default:
        return 'ยังไม่มีรายการชำระเงิน';
    }
  }

  const CustomerOrderDetailsView({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('คำสั่งซื้อ #${order.orderId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(context),

            const SizedBox(height: 16),

            _buildSection(
              context,
              title: 'ข้อมูลคำสั่งซื้อ',
              icon: Icons.receipt_long,
              children: [
                _detailRow('หมายเลขคำสั่งซื้อ', '#${order.orderId}'),
                _detailRow('เกม', order.gameName),
                _detailRow('แพ็กเกจ', order.packageName),
                _detailRow('Package ID', '${order.packageId}'),
                _detailRow(
                  'สถานะการชำระเงิน',
                  _paymentStatusLabel(order.paymentStatus),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              context,
              title: 'ข้อมูลผู้เล่น',
              icon: Icons.person,
              children: [
                _detailRow('Player UID', order.playerUid),
                if (order.serverCode.isNotEmpty)
                  _detailRow('Server ID', order.serverCode),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              context,
              title: 'รายละเอียดราคา',
              icon: Icons.payments,
              children: [
                _detailRow('ราคาแพ็กเกจ', _money(order.originalPrice)),
                _detailRow(
                  'ส่วนลดรวม',
                  '- ${_money(order.discountAmount)}',
                  valueColor: Colors.green,
                ),
                _detailRow(
                  'ส่วนลดจากคูปอง',
                  '- ${_money(order.couponDiscount)}',
                  valueColor: Colors.green,
                ),
                _detailRow('โค้ดคูปอง', order.couponCode ?? '-'),
                _detailRow('แต้มที่ใช้', '${order.spentPoints} แต้ม'),
                _detailRow('ค่าธรรมเนียม', _money(order.feeAmount)),
                const Divider(height: 24),
                _detailRow(
                  'ยอดชำระทั้งหมด',
                  _money(order.totalAmount),
                  isBold: true,
                  valueColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSection(
              context,
              title: 'วันและเวลา',
              icon: Icons.calendar_month,
              children: [
                _detailRow(
                  'วันที่สร้างคำสั่งซื้อ',
                  _formatDate(order.createdAt),
                ),
                _detailRow('วันที่เสร็จสิ้น', _formatDate(order.completedAt)),
              ],
            ),

            if (order.status == 'Pending' && order.paymentStatus != 'Paid') ...[
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _confirmCustomerCancelOrder(context, order);
                  },
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('ยกเลิกคำสั่งซื้อ'),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final color = _statusColor(order.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(_statusIcon(order.status), color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'สถานะคำสั่งซื้อ',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusLabel(order.status),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double value) {
    return '฿${value.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final local = date.toLocal();

    String twoDigits(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Pending':
        return 'รอดำเนินการ';
      case 'Processing':
        return 'กำลังดำเนินการ';
      case 'Completed':
        return 'สำเร็จ';
      case 'Cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
        return Colors.orange;
      case 'Processing':
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'Cancelled':
        return Icons.cancel;
      case 'Pending':
        return Icons.schedule;
      case 'Processing':
        return Icons.sync;
      default:
        return Icons.info;
    }
  }
}

// ========================================
// Customer Cancel Order
// ========================================
Future<void> _confirmCustomerCancelOrder(
  BuildContext context,
  OrderModel order,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยืนยันการยกเลิกคำสั่งซื้อ'),
        content: const Text(
          'ต้องการยกเลิกคำสั่งซื้อนี้ใช่หรือไม่?\n\n'
          'ระบบจะคืนแต้มที่ใช้และคืนคูปองให้ '
          'หากคำสั่งซื้อยังมีสิทธิ์ยกเลิก',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('กลับ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('ยืนยันยกเลิก'),
          ),
        ],
      );
    },
  );

  // ตรวจสอบหลังปิด Dialog ก่อนใช้ context อีกครั้ง
  if (confirmed != true || !context.mounted) {
    return;
  }

  // ดึง Service ก่อนเริ่ม Request
  final orderService = context.read<OrderService>();

  try {
    await orderService.cancelMyOrder(order.orderId);
    // ตรวจสอบอีกครั้งหลังเรียก API
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ยกเลิกคำสั่งซื้อเรียบร้อยแล้ว'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(true);
  } catch (error) {
    if (!context.mounted) return;
    final message = error is ApiException ? error.message : error.toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ไม่สามารถยกเลิกคำสั่งซื้อได้: $message'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
