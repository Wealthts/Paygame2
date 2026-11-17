import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/order_controller.dart';
import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/order_service.dart';

class OrderView extends StatelessWidget {
  const OrderView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return OrderController(context.read<OrderService>())..loadOrders();
      },
      child: const _OrderViewContent(),
    );
  }
}

class _OrderViewContent extends StatefulWidget {
  const _OrderViewContent();

  @override
  State<_OrderViewContent> createState() => _OrderViewContentState();
}

class _OrderViewContentState extends State<_OrderViewContent> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  static const List<String> _statusFilters = [
    'All',
    'Pending',
    'Processing',
    'Completed',
    'Cancelled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // Filter Orders
  // ========================================
  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();

    return orders.where((order) {
      final matchesStatus =
          _selectedStatus == 'All' || order.status == _selectedStatus;

      final searchableText = [
        order.orderId.toString(),
        order.userId.toString(),
        order.username ?? '',
        order.displayName ?? '',
        order.gameName,
        order.packageName,
        order.playerUid,
        order.serverCode,
        order.status,
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
        return 'รอดำเนินการ';
      case 'Processing':
        return 'กำลังดำเนินการ';
      case 'Completed':
        return 'เสร็จสิ้น';
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
        title: const Text('Orders Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<OrderController>().loadOrders();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Consumer<OrderController>(
        builder: (context, controller, child) {
          // กรองรายการคำสั่งซื้อ
          final visibleOrders = _filterOrders(controller.orders);

          return Column(
            children: [
              // แสดง Error Banner เมื่อมีข้อมูลอยู่แล้ว
              if (controller.errorMessage != null &&
                  controller.orders.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadOrders,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),

              // ช่องค้นหาและตัวกรองจะแสดงตลอดเวลา
              _buildSearchAndFilters(
                totalOrders: controller.orders.length,
                visibleOrders: visibleOrders.length,
              ),

              // ส่วนแสดงรายการคำสั่งซื้อ
              Expanded(child: _buildOrdersContent(controller, visibleOrders)),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // Orders Content
  // ========================================
  Widget _buildOrdersContent(
    OrderController controller,
    List<OrderModel> visibleOrders,
  ) {
    // Loading
    if (controller.isLoading && controller.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.orders.isEmpty) {
      return _ErrorView(
        message: controller.errorMessage!,
        onRetry: controller.loadOrders,
      );
    }

    // ไม่มีคำสั่งซื้อ
    if (controller.orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.loadOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 90),
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Center(child: Text('ยังไม่มีคำสั่งซื้อ')),
          ],
        ),
      );
    }

    // ไม่พบผลลัพธ์จากการค้นหา
    if (visibleOrders.isEmpty) {
      return _buildNoSearchResults();
    }

    // แสดงรายการคำสั่งซื้อ
    return RefreshIndicator(
      onRefresh: controller.loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleOrders.length,
        itemBuilder: (context, index) {
          final order = visibleOrders[index];

          return _OrderCard(
            order: order,
            isBusy: controller.busyOrderId == order.orderId,
            onViewDetails: () {
              _showOrderDetails(context, order);
            },
            onComplete: () async {
              await _confirmComplete(context, controller, order);
            },
            onCancel: () async {
              await _confirmCancel(context, controller, order);
            },
          );
        },
      ),
    );
  }

  // ========================================
  // Search & Filter UI
  // ========================================
  Widget _buildSearchAndFilters({
    required int totalOrders,
    required int visibleOrders,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ช่องค้นหา
          TextField(
            controller: _searchController,
            onChanged: (_) {
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'ค้นหา Order ID, ลูกค้า, เกม, UID ...',
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

          // ตัวกรองสถานะ
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

          // จำนวนรายการที่พบ
          Row(
            children: [
              Expanded(
                child: Text(
                  'แสดง $visibleOrders จาก $totalOrders รายการ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // ปุ่มล้างตัวกรอง
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
  // No Search Results
  // ========================================
  Widget _buildNoSearchResults() {
    return RefreshIndicator(
      onRefresh: () {
        return context.read<OrderController>().loadOrders();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),

          const Icon(Icons.search_off, size: 56, color: Colors.grey),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'ไม่พบคำสั่งซื้อที่ตรงกับการค้นหา',
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
// Order Card
// ========================================
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool isBusy;
  final VoidCallback onViewDetails;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const _OrderCard({
    required this.order,
    required this.isBusy,
    required this.onViewDetails,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == 'Pending';
    final isProcessing = order.status == 'Processing';

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
                    'Order #${order.orderId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              order.gameName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            Text('แพ็กเกจ: ${order.packageName}'),
            Text('ลูกค้า: ${order.displayName ?? order.username ?? '-'}'),
            Text('UID: ${order.playerUid}'),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('ยอดชำระ'),

                const Spacer(),

                Text(
                  '฿${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),

            if (order.createdAt != null)
              Text(
                'วันที่สั่งซื้อ: ${_formatDate(order.createdAt!)}',
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

                // จะแสดงปุ่มเสร็จสิ้นเมื่อชำระเงินแล้วและกำลังดำเนินการ
                if (isProcessing)
                  FilledButton.icon(
                    onPressed: isBusy ? null : onComplete,
                    icon: isBusy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('เสร็จสิ้น'),
                  ),

                // ยกเลิกได้เฉพาะ Pending
                if (isPending)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onCancel,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('ยกเลิก'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Status Chip
// ========================================
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'Completed':
        color = Colors.green;
        label = 'เสร็จสิ้น';
        break;

      case 'Cancelled':
        color = Colors.red;
        label = 'ยกเลิก';
        break;

      case 'Processing':
        color = Colors.blue;
        label = 'กำลังดำเนินการ';
        break;

      default:
        color = Colors.orange;
        label = status;
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
// Error View
// ========================================
class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
// Confirm Complete Order
// ========================================
Future<void> _confirmComplete(
  BuildContext context,
  OrderController controller,
  OrderModel order,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยืนยันการปิดคำสั่งซื้อ'),

        content: Text(
          'ต้องการเปลี่ยน Order #${order.orderId} เป็น Completed ใช่หรือไม่?',
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
    await controller.markAsCompleted(order.orderId);
  }
}

// ========================================
// Confirm Cancel Order
// ========================================
Future<void> _confirmCancel(
  BuildContext context,
  OrderController controller,
  OrderModel order,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('ยืนยันการยกเลิก'),

        content: Text('ต้องการยกเลิก Order #${order.orderId} ใช่หรือไม่?'),

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
            child: const Text('ยกเลิกคำสั่งซื้อ'),
          ),
        ],
      );
    },
  );

  if (confirmed == true) {
    await controller.cancelOrder(order.orderId);
  }
}

// ========================================
// Order Details Dialog
// ========================================
void _showOrderDetails(BuildContext context, OrderModel order) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Order #${order.orderId}'),

        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow('สถานะ', order.status),
                _detailRow('ลูกค้า', order.displayName ?? '-'),
                _detailRow('Username', order.username ?? '-'),
                _detailRow('Game', order.gameName),
                _detailRow('Package', order.packageName),
                _detailRow('Player UID', order.playerUid),
                _detailRow(
                  'Server Code',
                  order.serverCode.isEmpty ? '-' : order.serverCode,
                ),

                const Divider(),

                _detailRow(
                  'ราคาสินค้า',
                  '฿${order.originalPrice.toStringAsFixed(2)}',
                ),
                _detailRow(
                  'ส่วนลดรวม',
                  '฿${order.discountAmount.toStringAsFixed(2)}',
                ),
                _detailRow(
                  'ส่วนลดคูปอง',
                  '฿${order.couponDiscount.toStringAsFixed(2)}',
                ),
                _detailRow('Coupon', order.couponCode ?? '-'),
                _detailRow('แต้มที่ใช้', '${order.spentPoints}'),
                _detailRow(
                  'ค่าธรรมเนียม',
                  '฿${order.feeAmount.toStringAsFixed(2)}',
                ),
                _detailRow(
                  'ยอดชำระ',
                  '฿${order.totalAmount.toStringAsFixed(2)}',
                ),
                _detailRow(
                  'วันที่สร้าง',
                  order.createdAt == null ? '-' : _formatDate(order.createdAt!),
                ),
                _detailRow(
                  'วันที่เสร็จสิ้น',
                  order.completedAt == null
                      ? '-'
                      : _formatDate(order.completedAt!),
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