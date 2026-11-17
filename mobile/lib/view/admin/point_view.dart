import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/point_controller.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/point_service.dart';

class PointView extends StatelessWidget {
  const PointView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return PointController(context.read<PointService>())
          ..loadTransactions();
      },
      child: const _PointViewContent(),
    );
  }
}

// ========================================
// Point View Content
// ========================================
class _PointViewContent extends StatefulWidget {
  const _PointViewContent();

  @override
  State<_PointViewContent> createState() => _PointViewContentState();
}

class _PointViewContentState extends State<_PointViewContent> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'All';

  static const List<String> _typeFilters = ['All', 'Earn', 'Spend'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // Filter Transactions
  // ========================================

  List<PointModel> _filterTransactions(List<PointModel> transactions) {
    final query = _searchController.text.trim().toLowerCase();

    return transactions.where((transaction) {
      bool matchesType = true;

      if (_selectedType == 'Earn') {
        matchesType = transaction.pointsDelta > 0;
      } else if (_selectedType == 'Spend') {
        matchesType = transaction.pointsDelta < 0;
      }

      final searchableText = [
        transaction.pointTransactionId.toString(),
        transaction.userId.toString(),
        transaction.orderId?.toString() ?? '',
        transaction.username ?? '',
        transaction.displayName ?? '',
        transaction.eventKey,
        transaction.type,
        transaction.pointsDelta.toString(),
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesType && matchesSearch;
    }).toList();
  }

  // ========================================
  // Type Label
  // ========================================

  String _typeLabel(String type) {
    switch (type) {
      case 'All':
        return 'ทั้งหมด';
      case 'Earn':
        return 'ได้รับแต้ม';
      case 'Spend':
        return 'ใช้แต้ม';
      default:
        return type;
    }
  }

  // ========================================
  // Clear Filters
  // ========================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'All';
    });
  }

  // ========================================
  // Main Build
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Points Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<PointController>().loadTransactions();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddPointsDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มแต้ม'),
      ),

      body: Consumer<PointController>(
        builder: (context, controller, child) {
          final visibleTransactions = _filterTransactions(
            controller.transactions,
          );

          return Column(
            children: [
              // Summary
              _PointSummary(
                transactionCount: controller.transactions.length,
                totalEarned: controller.totalEarned,
                totalSpent: controller.totalSpent,
              ),

              // Error Banner
              if (controller.errorMessage != null &&
                  controller.transactions.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadTransactions,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),

              // Search and Filter
              _buildSearchAndFilters(
                totalTransactions: controller.transactions.length,
                visibleTransactions: visibleTransactions.length,
              ),

              // Transaction List
              Expanded(
                child: _buildTransactionsContent(
                  controller,
                  visibleTransactions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // Transactions Content
  // ========================================

  Widget _buildTransactionsContent(
    PointController controller,
    List<PointModel> visibleTransactions,
  ) {
    // Loading
    if (controller.isLoading && controller.transactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.transactions.isEmpty) {
      return _PointErrorView(
        message: controller.errorMessage!,
        onRetry: controller.loadTransactions,
      );
    }

    // No Transactions
    if (controller.transactions.isEmpty) {
      return _buildEmptyState(controller.loadTransactions);
    }

    // No Search Results
    if (visibleTransactions.isEmpty) {
      return _buildNoSearchResults(controller.loadTransactions);
    }

    // Show Transactions
    return RefreshIndicator(
      onRefresh: controller.loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleTransactions.length,
        itemBuilder: (context, index) {
          final transaction = visibleTransactions[index];

          return _PointCard(transaction: transaction);
        },
      ),
    );
  }

  // ========================================
  // Search and Filter UI
  // ========================================

  Widget _buildSearchAndFilters({
    required int totalTransactions,
    required int visibleTransactions,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
              hintText: 'ค้นหา Transaction ID, User ID, Username ...',
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

          // Type Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _typeFilters.map((type) {
                final isSelected = _selectedType == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_typeLabel(type)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedType = type;
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
                  'แสดง $visibleTransactions จาก '
                  '$totalTransactions รายการ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Clear Filters
              if (_searchController.text.isNotEmpty || _selectedType != 'All')
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

  Widget _buildEmptyState(Future<void> Function() onRefresh) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 90),
          Icon(Icons.stars_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Center(child: Text('ยังไม่มีประวัติแต้ม')),
        ],
      ),
    );
  }

  // ========================================
  // No Search Results
  // ========================================

  Widget _buildNoSearchResults(Future<void> Function() onRefresh) {
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
              'ไม่พบประวัติแต้มที่ตรงกับการค้นหา',
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

  // ========================================
  // Add Points Dialog
  // ========================================

  Future<void> _openAddPointsDialog(BuildContext context) async {
    final controller = context.read<PointController>();

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => const _AddPointsDialog(),
    );

    if (result == null || !context.mounted) return;

    final success = await controller.addPoints(
      userId: result['userId']!,
      points: result['points']!,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'เพิ่มแต้มให้สมาชิกเรียบร้อยแล้ว'
              : controller.errorMessage ?? 'เพิ่มแต้มไม่สำเร็จ',
        ),
      ),
    );
  }
}

// ========================================
// Point Summary
// ========================================

class _PointSummary extends StatelessWidget {
  final int transactionCount;
  final int totalEarned;
  final int totalSpent;

  const _PointSummary({
    required this.transactionCount,
    required this.totalEarned,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ภาพรวมประวัติแต้ม',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  title: 'รายการทั้งหมด',
                  value: '$transactionCount',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'แต้มที่ได้รับ',
                  value: '$totalEarned',
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  title: 'แต้มที่ใช้',
                  value: '$totalSpent',
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// Summary Card
// ========================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: Theme.of(context).textTheme.titleLarge),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Point Card
// ========================================

class _PointCard extends StatelessWidget {
  final PointModel transaction;

  const _PointCard({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isEarn = transaction.pointsDelta > 0;
    final isAutomatic = transaction.orderId != null;

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
                    'Transaction #${transaction.pointTransactionId}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    isEarn ? 'ได้รับแต้ม' : 'ใช้แต้ม',
                    style: TextStyle(
                      color: isEarn ? Colors.green : Colors.orange,
                    ),
                  ),
                  backgroundColor: (isEarn ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.12),
                  side: BorderSide.none,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              transaction.displayName ??
                  transaction.username ??
                  'User #${transaction.userId}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            Text('User ID: ${transaction.userId}'),

            Text('Event: ${transaction.eventKey}'),

            if (transaction.orderId != null)
              Text('Order ID: ${transaction.orderId}'),

            if (transaction.createdAt != null)
              Text(
                'วันที่: ${_formatDate(transaction.createdAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

            const Divider(height: 24),

            Row(
              children: [
                Text(
                  isAutomatic ? 'รายการจากระบบ Order' : 'รายการจาก Admin',
                  style: Theme.of(context).textTheme.bodySmall,
                ),

                const Spacer(),

                Text(
                  '${isEarn ? '+' : ''}'
                  '${transaction.pointsDelta} แต้ม',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isEarn ? Colors.green : Colors.red,
                  ),
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
// Add Points Dialog
// ========================================

class _AddPointsDialog extends StatefulWidget {
  const _AddPointsDialog();

  @override
  State<_AddPointsDialog> createState() => _AddPointsDialogState();
}

class _AddPointsDialogState extends State<_AddPointsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(context, {
      'userId': int.parse(_userIdController.text.trim()),
      'points': int.parse(_pointsController.text.trim()),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('เพิ่มแต้มให้สมาชิก'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _userIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'User ID',
                  hintText: 'เช่น 2',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final id = int.tryParse(value?.trim() ?? '');

                  if (id == null || id <= 0) {
                    return 'กรุณากรอก User ID ให้ถูกต้อง';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _pointsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'จำนวนแต้ม',
                  hintText: 'เช่น 100',
                  prefixIcon: Icon(Icons.stars_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final points = int.tryParse(value?.trim() ?? '');

                  if (points == null || points <= 0) {
                    return 'จำนวนแต้มต้องเป็นจำนวนเต็มมากกว่า 0';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 12),

              const Text(
                'ระบบจะบันทึกเป็นรายการ Earn '
                'และสร้าง Event Key ให้อัตโนมัติ',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(onPressed: _submit, child: const Text('เพิ่มแต้ม')),
      ],
    );
  }
}

// ========================================
// Point Error View
// ========================================

class _PointErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _PointErrorView({required this.message, required this.onRetry});

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
