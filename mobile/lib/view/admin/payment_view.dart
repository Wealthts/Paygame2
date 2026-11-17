import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/payment_controller.dart';
import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/payment_service.dart';

class PaymentView extends StatelessWidget {
  const PaymentView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return PaymentController(context.read<PaymentService>())
          ..loadPayments();
      },
      child: const _PaymentViewContent(),
    );
  }
}

class _PaymentViewContent extends StatefulWidget {
  const _PaymentViewContent();

  @override
  State<_PaymentViewContent> createState() => _PaymentViewContentState();
}

class _PaymentViewContentState extends State<_PaymentViewContent> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';

  static const List<String> _statusFilters = [
    'All',
    'Pending',
    'Paid',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // Filter Payments
  // ========================================
  List<PaymentModel> _filterPayments(List<PaymentModel> payments) {
    final query = _searchController.text.trim().toLowerCase();

    return payments.where((payment) {
      final matchesStatus =
          _selectedStatus == 'All' || payment.status == _selectedStatus;

      final searchableText = [
        payment.paymentId.toString(),
        payment.orderId.toString(),
        payment.transactionRef,
        payment.method,
        payment.amount.toString(),
        payment.amount.toStringAsFixed(2),
        payment.status,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  // ========================================
  // Status Label
  // ========================================
  String _statusLabel(String status) {
    switch (status) {
      case 'All':
        return 'ทั้งหมด';
      case 'Pending':
        return 'รอชำระเงิน';
      case 'Paid':
        return 'ชำระแล้ว';
      case 'Cancelled':
        return 'ยกเลิก';
      default:
        return status;
    }
  }

  // ========================================
  // Clear Filters
  // ========================================
  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
    });
  }

  // ========================================
  // Main Build
  // ========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<PaymentController>().loadPayments();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<PaymentController>(
        builder: (context, controller, child) {
          final visiblePayments = _filterPayments(controller.payments);

          return Column(
            children: [
              // Error Banner
              if (controller.errorMessage != null &&
                  controller.payments.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadPayments,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),

              // Search and Filter
              _buildSearchAndFilters(
                totalPayments: controller.payments.length,
                visiblePayments: visiblePayments.length,
              ),

              // Payment List
              Expanded(
                child: _buildPaymentsContent(controller, visiblePayments),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // Payment Content
  // ========================================
  Widget _buildPaymentsContent(
    PaymentController controller,
    List<PaymentModel> visiblePayments,
  ) {
    // Loading
    if (controller.isLoading && controller.payments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.payments.isEmpty) {
      return _PaymentErrorView(
        message: controller.errorMessage!,
        onRetry: controller.loadPayments,
      );
    }

    // No Payments
    if (controller.payments.isEmpty) {
      return _buildEmptyState(
        icon: Icons.payments_outlined,
        message: 'ยังไม่มีรายการชำระเงิน',
        onRefresh: controller.loadPayments,
      );
    }

    // No Search Results
    if (visiblePayments.isEmpty) {
      return _buildNoSearchResults(onRefresh: controller.loadPayments);
    }

    // Show Payments
    return RefreshIndicator(
      onRefresh: controller.loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visiblePayments.length,
        itemBuilder: (context, index) {
          final payment = visiblePayments[index];

          return _PaymentCard(
            payment: payment,
            isBusy: controller.busyPaymentId == payment.paymentId,
            onViewDetails: () {
              _showPaymentDetails(context, payment);
            },
            onMarkAsPaid: () async {
              await _confirmMarkAsPaid(context, controller, payment);
            },
            onCancel: () async {
              await _confirmCancelPayment(context, controller, payment);
            },
          );
        },
      ),
    );
  }

  // ========================================
  // Search and Filter UI
  // ========================================
  Widget _buildSearchAndFilters({
    required int totalPayments,
    required int visiblePayments,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Field
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'ค้นหา Payment ID, Order ID, Transaction Ref ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'ล้างคำค้นหา',
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                      icon: const Icon(Icons.close),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
          ),

          const SizedBox(height: 12),

          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((status) {
                final isSelected = _selectedStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = status;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Result Count
          Row(
            children: [
              Expanded(
                child: Text(
                  'แสดง $visiblePayments จาก $totalPayments รายการ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Clear Filters
              if (_searchController.text.isNotEmpty || _selectedStatus != 'All')
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 17),
                  label: const Text('ล้างตัวกรอง'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================
  // Empty State
  // ========================================
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Center(child: Text(message)),
        ],
      ),
    );
  }

  // ========================================
  // No Search Results
  // ========================================
  Widget _buildNoSearchResults({required Future<void> Function() onRefresh}) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.search_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'ไม่พบรายการชำระเงินที่ตรงกับการค้นหา',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('ล้างคำค้นหาและตัวกรอง'),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Payment Card
// ========================================

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  final bool isBusy;
  final VoidCallback onViewDetails;
  final VoidCallback onMarkAsPaid;
  final VoidCallback onCancel;

  const _PaymentCard({
    required this.payment,
    required this.isBusy,
    required this.onViewDetails,
    required this.onMarkAsPaid,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = payment.status == 'Pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payment #${payment.paymentId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _PaymentStatusChip(status: payment.status),
              ],
            ),

            const SizedBox(height: 10),

            Text('Order #${payment.orderId}'),

            Text('ช่องทาง: ${payment.method}'),

            Text(
              'เลขอ้างอิง: ${payment.transactionRef}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Text('ยอดชำระ'),
                const Spacer(),
                Text(
                  '฿${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            if (payment.createdAt != null)
              Text(
                'วันที่สร้าง: ${_formatDate(payment.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            if (payment.paidAt != null)
              Text(
                'วันที่ชำระ: ${_formatDate(payment.paidAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            const Divider(height: 24),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onViewDetails,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('รายละเอียด'),
                ),

                if (isPending) ...[
                  FilledButton.icon(
                    onPressed: isBusy ? null : onMarkAsPaid,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('ยืนยันชำระเงิน'),
                  ),

                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('ยกเลิก'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Payment Status Chip
// ========================================

class _PaymentStatusChip extends StatelessWidget {
  final String status;

  const _PaymentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'Paid':
        color = Colors.green;
        label = 'ชำระแล้ว';
        break;

      case 'Cancelled':
        color = Colors.red;
        label = 'ยกเลิก';
        break;

      default:
        color = Colors.orange;
        label = 'รอชำระเงิน';
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}

// ========================================
// Payment Error View
// ========================================

class _PaymentErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PaymentErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Confirm Mark As Paid
// ========================================

Future<void> _confirmMarkAsPaid(
  BuildContext context,
  PaymentController controller,
  PaymentModel payment,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยืนยันการชำระเงิน'),
        content: Text(
          'ยืนยันว่า Payment #${payment.paymentId} ได้รับเงินแล้วใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('กลับ'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    await controller.markAsPaid(payment.paymentId);
  }
}

// ========================================
// Confirm Cancel Payment
// ========================================

Future<void> _confirmCancelPayment(
  BuildContext context,
  PaymentController controller,
  PaymentModel payment,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยกเลิกรายการชำระเงิน'),
        content: Text(
          'ต้องการยกเลิก Payment #${payment.paymentId} ใช่หรือไม่?',
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

  if (confirmed == true) {
    await controller.cancelPayment(payment.paymentId);
  }
}

// ========================================
// Payment Details Dialog
// ========================================

void _showPaymentDetails(BuildContext context, PaymentModel payment) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Payment #${payment.paymentId}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('Payment ID', '${payment.paymentId}'),
                _detailRow('Order ID', '${payment.orderId}'),
                _detailRow('Transaction Ref', payment.transactionRef),
                _detailRow('Method', payment.method),
                _detailRow('Amount', '฿${payment.amount.toStringAsFixed(2)}'),
                _detailRow('Status', payment.status),
                _detailRow(
                  'Created At',
                  payment.createdAt == null
                      ? '-'
                      : _formatDate(payment.createdAt!),
                ),
                _detailRow(
                  'Paid At',
                  payment.paidAt == null ? '-' : _formatDate(payment.paidAt!),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('ปิด'),
          ),
        ],
      );
    },
  );
}

// ========================================
// Detail Row
// ========================================

Widget _detailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

// ========================================
// Date Formatter
// ========================================

String _formatDate(DateTime date) {
  final local = date.toLocal();

  String twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  return '${twoDigits(local.day)}/${twoDigits(local.month)}/${local.year} '
      '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
}
