import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controller/user_coupon_controller.dart';
import '../../model/coupon_model.dart';
import '../../model/user_coupon_model.dart';
import '../../service/coupon_service.dart';
import '../../service/user_coupon_service.dart';

class UserCouponView extends StatefulWidget {
  const UserCouponView({super.key});

  @override
  State<UserCouponView> createState() => _UserCouponViewState();
}

class _UserCouponViewState extends State<UserCouponView> {
  late final UserCouponController controller;

  final TextEditingController _searchController = TextEditingController();

  String _selectedUsage = 'All';
  String _selectedStatus = 'All';

  static const List<String> _usageFilters = ['All', 'Unused', 'Used'];

  static const List<String> _statusFilters = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();

    controller = UserCouponController(
      context.read<UserCouponService>(),
      context.read<CouponService>(),
    );

    controller.loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  // ========================================
  // Show Message
  // ========================================

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ========================================
  // Filter User Coupons
  // ========================================

  List<UserCouponModel> _filterUserCoupons(List<UserCouponModel> userCoupons) {
    final query = _searchController.text.trim().toLowerCase();

    return userCoupons.where((item) {
      // Filter Used / Unused
      final matchesUsage = switch (_selectedUsage) {
        'Used' => item.isUsed,
        'Unused' => !item.isUsed,
        _ => true,
      };

      // Filter Active / Inactive Coupon
      final matchesStatus = switch (_selectedStatus) {
        'Active' => item.couponIsActive,
        'Inactive' => !item.couponIsActive,
        _ => true,
      };

      // Search
      final searchableText = [
        item.userCouponId.toString(),
        item.userId.toString(),
        item.couponId.toString(),
        item.username,
        item.displayName,
        item.email,
        item.code,
        item.discountType,
        item.discountLabel,
        item.discountValue.toString(),
        item.minOrderAmount.toString(),
        item.startDate,
        item.endDate,
        item.usedAt ?? '',
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesUsage && matchesStatus && matchesSearch;
    }).toList();
  }

  // ========================================
  // Filter Labels
  // ========================================

  String _usageLabel(String value) {
    switch (value) {
      case 'All':
        return 'ทั้งหมด';
      case 'Unused':
        return 'ยังไม่ได้ใช้';
      case 'Used':
        return 'ใช้แล้ว';
      default:
        return value;
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'All':
        return 'ทุกสถานะ';
      case 'Active':
        return 'คูปองเปิดใช้งาน';
      case 'Inactive':
        return 'คูปองปิดใช้งาน';
      default:
        return value;
    }
  }

  // ========================================
  // Clear Filters
  // ========================================

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedUsage = 'All';
      _selectedStatus = 'All';
    });
  }

  // ========================================
  // Date Label
  // ========================================

  String _dateLabel(String? value) {
    if (value == null || value.isEmpty) {
      return '-';
    }

    return value.replaceFirst('T', ' ');
  }

  // ========================================
  // Assign Coupon Dialog
  // ========================================

  Future<void> _openAssignDialog() async {
    if (controller.isSaving) return;

    if (controller.users.isEmpty) {
      _showMessage('ไม่พบสมาชิกที่เปิดใช้งาน', isError: true);
      return;
    }

    if (controller.availableCoupons.isEmpty) {
      _showMessage(
        'ไม่พบคูปองที่เปิดใช้งาน กรุณาตรวจสอบหน้า Coupons',
        isError: true,
      );
      return;
    }

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (_) => AssignUserCouponDialog(
        users: controller.users,
        coupons: controller.availableCoupons,
      ),
    );

    if (result == null || !mounted) return;

    try {
      await controller.assignCoupon(
        userId: result['user_id']!,
        couponId: result['coupon_id']!,
      );

      _showMessage('มอบคูปองให้สมาชิกเรียบร้อยแล้ว');
    } catch (e) {
      _showMessage('มอบคูปองไม่สำเร็จ: $e', isError: true);
    }
  }

  // ========================================
  // Main Build
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('คูปองของสมาชิก'),
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: controller.isLoading
                ? null
                : () => controller.loadData(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isSaving ? null : _openAssignDialog,
        icon: const Icon(Icons.card_giftcard),
        label: const Text('มอบคูปอง'),
      ),

      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final visibleCoupons = _filterUserCoupons(controller.userCoupons);

          return Column(
            children: [
              // Summary
              _buildSummary(),

              // Error Banner
              if (controller.errorMessage != null &&
                  controller.userCoupons.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadData,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),

              // Search and Filters
              _buildSearchAndFilters(
                totalCoupons: controller.userCoupons.length,
                visibleCoupons: visibleCoupons.length,
              ),

              // User Coupon List
              Expanded(child: _buildUserCouponContent(visibleCoupons)),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // User Coupon Content
  // ========================================

  Widget _buildUserCouponContent(List<UserCouponModel> visibleCoupons) {
    // Loading
    if (controller.isLoading && controller.userCoupons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.userCoupons.isEmpty) {
      return _buildErrorView();
    }

    // Empty
    if (controller.userCoupons.isEmpty) {
      return _buildEmptyView();
    }

    // No Search Results
    if (visibleCoupons.isEmpty) {
      return _buildNoResults();
    }

    // Show Results
    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleCoupons.length,
        itemBuilder: (context, index) {
          return _buildUserCouponCard(visibleCoupons[index]);
        },
      ),
    );
  }

  // ========================================
  // Search and Filter UI
  // ========================================

  Widget _buildSearchAndFilters({
    required int totalCoupons,
    required int visibleCoupons,
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
              hintText: 'ค้นหา Assignment ID, สมาชิก, Coupon Code ...',
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

          // Used / Unused Filter
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'สถานะการใช้คูปอง',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _usageFilters.map((value) {
                final selected = _selectedUsage == value;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_usageLabel(value)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedUsage = value;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Active / Inactive Filter
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'สถานะคูปอง',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),

          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((value) {
                final selected = _selectedStatus == value;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(value)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedStatus = value;
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
                  'แสดง $visibleCoupons จาก $totalCoupons รายการ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              if (_searchController.text.isNotEmpty ||
                  _selectedUsage != 'All' ||
                  _selectedStatus != 'All')
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
  // Summary
  // ========================================

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'มอบคูปองแล้ว',
              value: controller.totalAssignments.toString(),
              icon: Icons.card_giftcard,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _SummaryCard(
              title: 'ยังไม่ได้ใช้',
              value: controller.unusedAssignments.toString(),
              icon: Icons.confirmation_number_outlined,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _SummaryCard(
              title: 'ใช้แล้ว',
              value: controller.usedAssignments.toString(),
              icon: Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // User Coupon Card
  // ========================================

  Widget _buildUserCouponCard(UserCouponModel item) {
    final isUsed = item.isUsed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        '@${item.username}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                Chip(
                  label: Text(isUsed ? 'ใช้แล้ว' : 'ยังไม่ได้ใช้'),
                  backgroundColor: isUsed
                      ? Colors.grey.shade300
                      : Colors.green.shade100,
                ),
              ],
            ),

            const Divider(height: 24),

            // Coupon Information
            Text(
              'คูปอง: ${item.code}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),

            Text('ส่วนลด: ${item.discountLabel}'),

            Text(
              'ยอดสั่งซื้อขั้นต่ำ: '
              '฿${item.minOrderAmount.toStringAsFixed(2)}',
            ),

            Text('อีเมลสมาชิก: ${item.email}'),

            Text('วันหมดอายุคูปอง: ${_dateLabel(item.endDate)}'),

            if (isUsed)
              Text(
                'ใช้เมื่อ: ${_dateLabel(item.usedAt)}',
                style: const TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 8),

            // Assignment Information
            Row(
              children: [
                Text(
                  'Assignment ID: ${item.userCouponId}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const Spacer(),

                if (!item.couponIsActive)
                  const Text(
                    'คูปองถูกปิดใช้งาน',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Empty View
  // ========================================

  Widget _buildEmptyView() {
    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 90),

          Icon(Icons.card_giftcard, size: 64, color: Colors.grey),

          SizedBox(height: 16),

          Center(child: Text('ยังไม่มีการมอบคูปองให้สมาชิก')),
        ],
      ),
    );
  }

  // ========================================
  // No Results
  // ========================================

  Widget _buildNoResults() {
    return RefreshIndicator(
      onRefresh: () => controller.loadData(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),

          const Icon(Icons.search_off, size: 56, color: Colors.grey),

          const SizedBox(height: 12),

          const Center(
            child: Text(
              'ไม่พบคูปองของสมาชิกที่ตรงกับการค้นหา',
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
  // Error View
  // ========================================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),

            const SizedBox(height: 12),

            Text(controller.errorMessage!, textAlign: TextAlign.center),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: () => controller.loadData(),
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
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
          children: [
            Icon(icon, size: 25),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// Assign User Coupon Dialog
// ========================================

class AssignUserCouponDialog extends StatefulWidget {
  final List<UserOptionModel> users;
  final List<CouponModel> coupons;

  const AssignUserCouponDialog({
    super.key,
    required this.users,
    required this.coupons,
  });

  @override
  State<AssignUserCouponDialog> createState() => _AssignUserCouponDialogState();
}

class _AssignUserCouponDialogState extends State<AssignUserCouponDialog> {
  final _formKey = GlobalKey<FormState>();

  int? selectedUserId;
  int? selectedCouponId;

  @override
  void initState() {
    super.initState();

    selectedUserId = widget.users.first.userId;
    selectedCouponId = widget.coupons.first.couponId;
  }

  // ========================================
  // Submit Assignment
  // ========================================

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedUserId == null || selectedCouponId == null) {
      return;
    }

    Navigator.pop(context, {
      'user_id': selectedUserId!,
      'coupon_id': selectedCouponId!,
    });
  }

  // ========================================
  // Build Dialog
  // ========================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('มอบคูปองให้สมาชิก'),

      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Select Member
              DropdownButtonFormField<int>(
                initialValue: selectedUserId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'เลือกสมาชิก'),
                items: widget.users.map((user) {
                  return DropdownMenuItem<int>(
                    value: user.userId,
                    child: Text(
                      '${user.label} - ${user.email}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedUserId = value;
                  });
                },
                validator: (value) {
                  return value == null ? 'กรุณาเลือกสมาชิก' : null;
                },
              ),

              const SizedBox(height: 16),

              // Select Coupon
              DropdownButtonFormField<int>(
                initialValue: selectedCouponId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'เลือกคูปอง'),
                items: widget.coupons.map((coupon) {
                  return DropdownMenuItem<int>(
                    value: coupon.couponId,
                    child: Text(
                      '${coupon.code} - ${coupon.discountLabel}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCouponId = value;
                  });
                },
                validator: (value) {
                  return value == null ? 'กรุณาเลือกคูปอง' : null;
                },
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

        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.card_giftcard),
          label: const Text('มอบคูปอง'),
        ),
      ],
    );
  }
}
