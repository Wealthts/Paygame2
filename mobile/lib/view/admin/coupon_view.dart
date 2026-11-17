import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../controller/coupon_controller.dart';
import '../../model/coupon_model.dart';
import '../../service/coupon_service.dart';

class CouponView extends StatefulWidget {
  const CouponView({super.key});

  @override
  State<CouponView> createState() => _CouponViewState();
}

class _CouponViewState extends State<CouponView> {
  late final CouponController controller;

  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'All';
  String _selectedDiscountType = 'All';

  static const List<String> _statusFilters = ['All', 'Active', 'Inactive'];

  static const List<String> _discountFilters = ['All', 'fixed', 'percent'];

  @override
  void initState() {
    super.initState();

    controller = CouponController(context.read<CouponService>());
    controller.loadCoupons();
  }

  @override
  void dispose() {
    _searchController.dispose();
    controller.dispose();
    super.dispose();
  }

  // ========================================
  // Message
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
  // Filter Coupons
  // ========================================

  List<CouponModel> _filterCoupons(List<CouponModel> coupons) {
    final query = _searchController.text.trim().toLowerCase();

    return coupons.where((coupon) {
      // Filter Active / Inactive
      final matchesStatus = switch (_selectedStatus) {
        'Active' => coupon.isActive,
        'Inactive' => !coupon.isActive,
        _ => true,
      };

      // Filter Discount Type
      final matchesDiscountType =
          _selectedDiscountType == 'All' ||
          coupon.discountType == _selectedDiscountType;

      // Search
      final searchableText = [
        coupon.couponId.toString(),
        coupon.code,
        coupon.discountType,
        coupon.discountLabel,
        coupon.discountValue.toString(),
        coupon.minOrderAmount.toString(),
        coupon.maxDiscountAmount?.toString() ?? '',
        coupon.useCount.toString(),
        coupon.useLimit?.toString() ?? '',
        coupon.startDate,
        coupon.endDate,
      ].join(' ').toLowerCase();

      final matchesSearch = query.isEmpty || searchableText.contains(query);

      return matchesStatus && matchesDiscountType && matchesSearch;
    }).toList();
  }

  // ========================================
  // Status Label
  // ========================================

  String _statusLabel(String status) {
    switch (status) {
      case 'All':
        return 'ทั้งหมด';
      case 'Active':
        return 'เปิดใช้งาน';
      case 'Inactive':
        return 'ปิดใช้งาน';
      default:
        return status;
    }
  }

  // ========================================
  // Discount Label
  // ========================================

  String _discountTypeLabel(String type) {
    switch (type) {
      case 'All':
        return 'ทุกประเภท';
      case 'fixed':
        return 'ลดเป็นบาท';
      case 'percent':
        return 'ลดเป็นเปอร์เซ็นต์';
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
      _selectedStatus = 'All';
      _selectedDiscountType = 'All';
    });
  }

  // ========================================
  // Date Label
  // ========================================

  String _dateLabel(String value) {
    if (value.isEmpty) return '-';
    return value.replaceFirst('T', ' ');
  }

  // ========================================
  // Open Coupon Form
  // ========================================

  Future<void> _openCouponForm({CouponModel? coupon}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CouponFormDialog(coupon: coupon),
    );

    if (result == null || !mounted) return;

    try {
      await controller.saveCoupon(couponId: coupon?.couponId, body: result);

      _showMessage(
        coupon == null ? 'เพิ่มคูปองเรียบร้อยแล้ว' : 'แก้ไขคูปองเรียบร้อยแล้ว',
      );
    } catch (e) {
      _showMessage('บันทึกคูปองไม่สำเร็จ: $e', isError: true);
    }
  }

  // ========================================
  // Toggle Coupon Status
  // ========================================

  Future<void> _toggleStatus(CouponModel coupon, bool value) async {
    try {
      await controller.setCouponStatus(coupon.couponId, value);

      if (!mounted) return;

      _showMessage(value ? 'เปิดใช้งานคูปองแล้ว' : 'ปิดใช้งานคูปองแล้ว');
    } catch (e) {
      _showMessage('เปลี่ยนสถานะไม่สำเร็จ: $e', isError: true);
    }
  }

  // ========================================
  // Main Build
  // ========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการคูปอง'),
        actions: [
          IconButton(
            onPressed: controller.isLoading
                ? null
                : () => controller.loadCoupons(),
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.isSaving ? null : () => _openCouponForm(),
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มคูปอง'),
      ),

      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final visibleCoupons = _filterCoupons(controller.coupons);

          return Column(
            children: [
              // Summary
              _buildSummary(),

              // Search and Filters
              _buildSearchAndFilters(
                totalCoupons: controller.coupons.length,
                visibleCoupons: visibleCoupons.length,
              ),

              // Error Banner
              if (controller.errorMessage != null &&
                  controller.coupons.isNotEmpty)
                MaterialBanner(
                  content: Text(controller.errorMessage!),
                  actions: [
                    TextButton(
                      onPressed: controller.loadCoupons,
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),

              // Coupon List
              Expanded(child: _buildCouponContent(visibleCoupons)),
            ],
          );
        },
      ),
    );
  }

  // ========================================
  // Coupon Content
  // ========================================

  Widget _buildCouponContent(List<CouponModel> visibleCoupons) {
    // Loading
    if (controller.isLoading && controller.coupons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error
    if (controller.errorMessage != null && controller.coupons.isEmpty) {
      return _buildErrorView();
    }

    // Empty
    if (controller.coupons.isEmpty) {
      return _buildEmptyView();
    }

    // No Search Results
    if (visibleCoupons.isEmpty) {
      return _buildNoResults();
    }

    // Show Coupons
    return RefreshIndicator(
      onRefresh: () => controller.loadCoupons(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleCoupons.length,
        itemBuilder: (context, index) {
          final coupon = visibleCoupons[index];

          return _buildCouponCard(coupon);
        },
      ),
    );
  }

  // ========================================
  // Search and Filters UI
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
              hintText: 'ค้นหา Coupon ID หรือ Coupon Code ...',
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
                final selected = _selectedStatus == status;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusLabel(status)),
                    selected: selected,
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

          const SizedBox(height: 8),

          // Discount Type Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _discountFilters.map((type) {
                final selected = _selectedDiscountType == type;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_discountTypeLabel(type)),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedDiscountType = type;
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
                  _selectedStatus != 'All' ||
                  _selectedDiscountType != 'All')
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
              title: 'คูปองทั้งหมด',
              value: controller.totalCoupons.toString(),
              icon: Icons.confirmation_number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'เปิดใช้งาน',
              value: controller.activeCoupons.toString(),
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              title: 'ปิดใช้งาน',
              value: controller.inactiveCoupons.toString(),
              icon: Icons.pause_circle_outline,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Coupon Card
  // ========================================

  Widget _buildCouponCard(CouponModel coupon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                IconButton(
                  tooltip: 'แก้ไข',
                  onPressed: controller.isSaving
                      ? null
                      : () => _openCouponForm(coupon: coupon),
                  icon: const Icon(Icons.edit),
                ),

                Switch(
                  value: coupon.isActive,
                  onChanged: controller.isSaving
                      ? null
                      : (value) => _toggleStatus(coupon, value),
                ),
              ],
            ),

            Text(
              'ส่วนลด: ${coupon.discountLabel}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            Text('Coupon ID: ${coupon.couponId}'),

            Text(
              'ยอดสั่งซื้อขั้นต่ำ: '
              '฿${coupon.minOrderAmount.toStringAsFixed(2)}',
            ),

            Text(
              'ส่วนลดสูงสุด: '
              '${coupon.maxDiscountAmount == null ? "ไม่จำกัด" : "฿${coupon.maxDiscountAmount!.toStringAsFixed(2)}"}',
            ),

            Text('จำนวนการใช้: ${coupon.usageLabel}'),

            Text(
              'ประเภทส่วนลด: '
              '${_discountTypeLabel(coupon.discountType)}',
            ),

            Text('เริ่มใช้: ${_dateLabel(coupon.startDate)}'),

            Text('หมดอายุ: ${_dateLabel(coupon.endDate)}'),

            const SizedBox(height: 6),

            Align(
              alignment: Alignment.centerRight,
              child: Text(
                coupon.isActive ? 'กำลังเปิดใช้งาน' : 'ปิดใช้งาน',
                style: TextStyle(
                  color: coupon.isActive ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      onRefresh: () => controller.loadCoupons(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 90),
          Icon(
            Icons.confirmation_number_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Center(child: Text('ยังไม่มีข้อมูลคูปอง')),
        ],
      ),
    );
  }

  // ========================================
  // No Results
  // ========================================

  Widget _buildNoResults() {
    return RefreshIndicator(
      onRefresh: () => controller.loadCoupons(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 90),
          const Icon(Icons.search_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'ไม่พบคูปองที่ตรงกับการค้นหา',
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
              onPressed: () => controller.loadCoupons(),
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
// Coupon Form Dialog
// ========================================

class CouponFormDialog extends StatefulWidget {
  final CouponModel? coupon;

  const CouponFormDialog({super.key, this.coupon});

  @override
  State<CouponFormDialog> createState() => _CouponFormDialogState();
}

class _CouponFormDialogState extends State<CouponFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController codeController;
  late final TextEditingController discountValueController;
  late final TextEditingController minOrderController;
  late final TextEditingController maxDiscountController;
  late final TextEditingController useLimitController;
  late final TextEditingController startDateController;
  late final TextEditingController endDateController;

  String discountType = 'fixed';

  String _formatDateTime(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');

    return '${date.year}-${two(date.month)}-${two(date.day)} '
        '${two(date.hour)}:${two(date.minute)}:${two(date.second)}';
  }

  @override
  void initState() {
    super.initState();

    final coupon = widget.coupon;
    final now = DateTime.now();

    codeController = TextEditingController(text: coupon?.code ?? '');

    discountValueController = TextEditingController(
      text: coupon?.discountValue.toString() ?? '',
    );

    minOrderController = TextEditingController(
      text: coupon?.minOrderAmount.toString() ?? '0',
    );

    maxDiscountController = TextEditingController(
      text: coupon?.maxDiscountAmount?.toString() ?? '',
    );

    useLimitController = TextEditingController(
      text: coupon?.useLimit?.toString() ?? '',
    );

    startDateController = TextEditingController(
      text: coupon?.startDate ?? _formatDateTime(now),
    );

    endDateController = TextEditingController(
      text:
          coupon?.endDate ?? _formatDateTime(now.add(const Duration(days: 30))),
    );

    discountType = coupon?.discountType ?? 'fixed';
  }

  @override
  void dispose() {
    codeController.dispose();
    discountValueController.dispose();
    minOrderController.dispose();
    maxDiscountController.dispose();
    useLimitController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }

  // ========================================
  // Date Validator
  // ========================================

  String? _dateValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'กรุณาระบุวันและเวลา';
    }

    final parsed = DateTime.tryParse(value.trim().replaceFirst(' ', 'T'));

    if (parsed == null) {
      return 'รูปแบบต้องเป็น YYYY-MM-DD HH:mm:ss';
    }

    return null;
  }

  // ========================================
  // Submit
  // ========================================

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final discountValue = double.tryParse(discountValueController.text.trim());

    final minOrder = double.tryParse(minOrderController.text.trim());

    final maxDiscount = maxDiscountController.text.trim().isEmpty
        ? null
        : double.tryParse(maxDiscountController.text.trim());

    final useLimit = useLimitController.text.trim().isEmpty
        ? null
        : int.tryParse(useLimitController.text.trim());

    if (discountValue == null || minOrder == null) return;

    final startDate = startDateController.text.trim();
    final endDate = endDateController.text.trim();

    final start = DateTime.tryParse(startDate.replaceFirst(' ', 'T'));

    final end = DateTime.tryParse(endDate.replaceFirst(' ', 'T'));

    if (start == null || end == null || !start.isBefore(end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('วันสิ้นสุดต้องอยู่หลังวันเริ่มต้น')),
      );
      return;
    }

    Navigator.pop(context, <String, dynamic>{
      'code': codeController.text.trim().toUpperCase(),
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrder,
      'max_discount_amount': maxDiscount,
      'use_limit': useLimit,
      'start_date': startDate,
      'end_date': endDate,
    });
  }

  // ========================================
  // Build Form
  // ========================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.coupon == null ? 'เพิ่มคูปอง' : 'แก้ไขคูปอง'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'รหัสคูปอง',
                    hintText: 'เช่น SAVE20',
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรหัสคูปอง';
                    }

                    if (value.trim().length > 50) {
                      return 'รหัสคูปองยาวเกินไป';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  initialValue: discountType,
                  decoration: const InputDecoration(labelText: 'ประเภทส่วนลด'),
                  items: const [
                    DropdownMenuItem(
                      value: 'fixed',
                      child: Text('ลดเป็นจำนวนเงิน (บาท)'),
                    ),
                    DropdownMenuItem(
                      value: 'percent',
                      child: Text('ลดเป็นเปอร์เซ็นต์ (%)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        discountType = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: discountValueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'มูลค่าส่วนลด'),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');

                    if (number == null || number <= 0) {
                      return 'กรุณาระบุมูลค่าส่วนลดให้ถูกต้อง';
                    }

                    if (discountType == 'percent' && number > 100) {
                      return 'เปอร์เซ็นต์ต้องไม่เกิน 100';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: minOrderController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'ยอดสั่งซื้อขั้นต่ำ (บาท)',
                  ),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');

                    if (number == null || number < 0) {
                      return 'กรุณาระบุยอดขั้นต่ำให้ถูกต้อง';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: maxDiscountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'ส่วนลดสูงสุด (เว้นว่างได้)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final number = double.tryParse(value);

                    if (number == null || number <= 0) {
                      return 'กรุณาระบุส่วนลดสูงสุดให้ถูกต้อง';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: useLimitController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'จำนวนครั้งที่ใช้ได้ (เว้นว่าง = ไม่จำกัด)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return null;
                    }

                    final number = int.tryParse(value);

                    if (number == null || number <= 0) {
                      return 'กรุณาระบุจำนวนครั้งเป็นจำนวนเต็มมากกว่า 0';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'วันและเวลาเริ่มต้น',
                    hintText: 'YYYY-MM-DD HH:mm:ss',
                  ),
                  validator: _dateValidator,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'วันและเวลาสิ้นสุด',
                    hintText: 'YYYY-MM-DD HH:mm:ss',
                  ),
                  validator: _dateValidator,
                ),

                const SizedBox(height: 8),

                const Text(
                  'กรอกวันและเวลาในรูปแบบ YYYY-MM-DD HH:mm:ss',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('บันทึก')),
      ],
    );
  }
}
