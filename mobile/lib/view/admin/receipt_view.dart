import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:mobile/controller/admin/receipt_controller.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/receipt_service.dart';

class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) {
        return ReceiptController(context.read<ReceiptService>())
          ..loadReceipts();
      },
      child: const _ReceiptViewContent(),
    );
  }
}

// ========================================
// Receipt View Content
// ========================================

class _ReceiptViewContent extends StatefulWidget {
  const _ReceiptViewContent();

  @override
  State<_ReceiptViewContent> createState() => _ReceiptViewContentState();
}

class _ReceiptViewContentState extends State<_ReceiptViewContent> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedPeriod = 'All';

  static const List<String> _periodFilters = ['All', 'Today', '7d', '30d'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ========================================
  // Filter Receipts
  // ========================================

  List<ReceiptModel> _filterReceipts(List<ReceiptModel> receipts) {
    final query = _searchController.text.trim().toLowerCase();

    return receipts.where((receipt) {
      final searchableText = [
        receipt.receiptId.toString(),
        receipt.orderId.toString(),
        receipt.receiptNumber,
        receipt.issuedAt?.toString() ?? '',
        receipt.issuedAt == null ? '' : _formatDate(receipt.issuedAt!),
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      final matchesPeriod = _matchesDateFilter(receipt);

      return matchesSearch && matchesPeriod;
    }).toList();
  }

  // ========================================
  // Date Filter
  // ========================================

  bool _matchesDateFilter(ReceiptModel receipt) {
    if (_selectedPeriod == 'All') {
      return true;
    }

    if (receipt.issuedAt == null) {
      return false;
    }

    final now = DateTime.now();
    final issued = receipt.issuedAt!.toLocal();

    final today = DateTime(now.year, now.month, now.day);

    final receiptDate = DateTime(issued.year, issued.month, issued.day);

    switch (_selectedPeriod) {
      case 'Today':
        return receiptDate == today && !issued.isAfter(now);

      case '7d':
        final startDate = today.subtract(const Duration(days: 6));

        return !receiptDate.isBefore(startDate) &&
            !receiptDate.isAfter(today) &&
            !issued.isAfter(now);

      case '30d':
        final startDate = today.subtract(const Duration(days: 29));

        return !receiptDate.isBefore(startDate) &&
            !receiptDate.isAfter(today) &&
            !issued.isAfter(now);

      default:
        return true;
    }
  }

  // ========================================
  // Period Label
  // ========================================

  String _periodLabel(String period) {
    switch (period) {
      case 'All':
        return 'All';
      case 'Today':
        return 'Today';
      case '7d':
        return 'Last 7 days';
      case '30d':
        return 'Last 30 days';
      default:
        return period;
    }
  }

  // ========================================
  // Clear Filters
  // ========================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedPeriod = 'All';
    });
  }

  // ========================================
  // Main Build
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              context.read<ReceiptController>().loadReceipts();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: Consumer<ReceiptController>(
        builder: (context, controller, child) {
          final visibleReceipts = _filterReceipts(controller.receipts);

          return Column(
            children: [
              // Receipt Summary
              _ReceiptSummary(count: controller.receipts.length),

              // Error Banner
              if (controller.errorMessage != null &&
                  controller.receipts.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadReceipts,
                      child: const Text('Try again'),
                    ),
                  ],
                ),

              // Search and Filters
              _buildSearchAndFilters(
                totalReceipts: controller.receipts.length,
                visibleReceipts: visibleReceipts.length,
              ),

              // Receipt List
              Expanded(
                child: _buildReceiptsContent(controller, visibleReceipts),
              ),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // Receipts Content
  // ========================================

  Widget _buildReceiptsContent(
    ReceiptController controller,
    List<ReceiptModel> visibleReceipts,
  ) {
    // Loading
    if (controller.isLoading && controller.receipts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.receipts.isEmpty) {
      return _ReceiptErrorView(
        message: controller.errorMessage!,
        onRetry: controller.loadReceipts,
      );
    }

    // Empty
    if (controller.receipts.isEmpty) {
      return _buildEmptyState(controller.loadReceipts);
    }

    // No Search Results
    if (visibleReceipts.isEmpty) {
      return _buildNoSearchResults(controller.loadReceipts);
    }

    // Show Receipts
    return RefreshIndicator(
      onRefresh: controller.loadReceipts,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleReceipts.length,
        itemBuilder: (context, index) {
          final receipt = visibleReceipts[index];

          return _ReceiptCard(
            receipt: receipt,
            onTap: () {
              _showReceiptDetails(context, receipt);
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
    required int totalReceipts,
    required int visibleReceipts,
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
              hintText: 'Search Receipt ID, Order ID, Receipt Number ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
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

          // Date Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periodFilters.map((period) {
                final isSelected = _selectedPeriod == period;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_periodLabel(period)),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedPeriod = period;
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
                  'Showing $visibleReceipts of '
                  '$totalReceipts items',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              if (_searchController.text.isNotEmpty || _selectedPeriod != 'All')
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off, size: 17),
                  label: const Text('Clear filters'),
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
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Center(child: Text('No receipts yet')),
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
              'No receipts match your filters',
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Clear search and filters'),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// Receipt Summary
// ========================================

class _ReceiptSummary extends StatelessWidget {
  final int count;

  const _ReceiptSummary({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('All receipts'),
                    const SizedBox(height: 4),
                    Text(
                      '$count items',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// Receipt Card
// ========================================

class _ReceiptCard extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback onTap;

  const _ReceiptCard({required this.receipt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_outlined, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      receipt.receiptNumber,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),

              const Divider(height: 24),

              Text('Receipt ID: ${receipt.receiptId}'),
              Text('Order ID: ${receipt.orderId}'),

              const SizedBox(height: 6),

              Text(
                'Issued: '
                '${receipt.issuedAt == null ? '-' : _formatDate(receipt.issuedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View details'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================
// Receipt Details Dialog
// ========================================

void _showReceiptDetails(BuildContext context, ReceiptModel receipt) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.receipt_long_outlined),
            SizedBox(width: 10),
            Text('Receipt Details'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _receiptDetail('Receipt ID', '${receipt.receiptId}'),
              _receiptDetail('Receipt Number', receipt.receiptNumber),
              _receiptDetail('Order ID', '${receipt.orderId}'),
              _receiptDetail(
                'Issued At',
                receipt.issuedAt == null ? '-' : _formatDate(receipt.issuedAt!),
              ),

              const Divider(height: 24),

              const Text(
                'This receipt was generated by PayGame '
                'and cannot be edited here.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

// ========================================
// Receipt Detail Row
// ========================================

Widget _receiptDetail(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
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
        Expanded(child: SelectableText(value)),
      ],
    ),
  );
}

// ========================================
// Receipt Error View
// ========================================

class _ReceiptErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ReceiptErrorView({required this.message, required this.onRetry});

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
              label: const Text('Try again'),
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
