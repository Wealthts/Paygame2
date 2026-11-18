import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:provider/provider.dart';

import '../../model/user_coupon_model.dart';
import '../../service/user_coupon_service.dart';

class CustomerCouponView extends StatefulWidget {
  const CustomerCouponView({super.key});

  @override
  State<CustomerCouponView> createState() => _CustomerCouponViewState();
}

class _CustomerCouponViewState extends State<CustomerCouponView> {
  final _couponCodeController = TextEditingController();
  late Future<List<CustomerCouponModel>> _couponsFuture;

  int _selectedFilter = 0;
  bool _isClaimingCoupon = false;

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  // ========================================
  // Load Coupons
  // ========================================
  void _loadCoupons() {
    _couponsFuture = context.read<UserCouponService>().getMyCoupons();
  }

  // ========================================
  // Refresh Coupons
  // ========================================
  Future<void> _refreshCoupons() async {
    final future = context.read<UserCouponService>().getMyCoupons();

    setState(() {
      _couponsFuture = future;
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
    setState(_loadCoupons);
  }

  Future<void> _claimCoupon() async {
    final code = _couponCodeController.text.trim();
    if (_isClaimingCoupon) return;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกรหัสคูปอง')),
      );
      return;
    }

    setState(() => _isClaimingCoupon = true);
    try {
      await context.read<UserCouponService>().claimCouponByCode(code);
      if (!mounted) return;
      _couponCodeController.clear();
      setState(() {
        _isClaimingCoupon = false;
        _loadCoupons();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('เพิ่มคูปองเข้าบัญชีแล้ว')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _isClaimingCoupon = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  // ========================================
  // Filter Coupons
  // ========================================
  List<CustomerCouponModel> _filterCoupons(List<CustomerCouponModel> coupons) {
    switch (_selectedFilter) {
      case 1:
        return coupons.where((coupon) => coupon.isAvailable).toList();

      case 2:
        return coupons.where((coupon) => !coupon.isAvailable).toList();

      default:
        return coupons;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: const Text('คูปองของฉัน'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<CustomerCouponModel>>(
          future: _couponsFuture,
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
                      'กำลังโหลดคูปอง...',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              );
            }

            // Error
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError();
            }

            final coupons = snapshot.data!;
            final filteredCoupons = _filterCoupons(coupons);

            final availableCount = coupons
                .where((coupon) => coupon.isAvailable)
                .length;

            final usedCount = coupons.where((coupon) => coupon.isUsed).length;

            return RefreshIndicator(
              onRefresh: _refreshCoupons,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSummary(
                    total: coupons.length,
                    available: availableCount,
                    used: usedCount,
                  ),

                  const SizedBox(height: 16),

                  _buildClaimCoupon(),

                  const SizedBox(height: 24),

                  const Text(
                    'รายการคูปอง',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildFilters(),

                  const SizedBox(height: 16),

                  if (filteredCoupons.isEmpty)
                    _buildEmpty()
                  else
                    ...filteredCoupons.map(
                      (coupon) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _CouponCard(coupon: coupon),
                      ),
                    ),

                  const SizedBox(height: 20),

                  const Center(
                    child: Text(
                      'คูปองที่ได้รับจากระบบ PayGame',
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

  Widget _buildClaimCoupon() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'มีโค้ดคูปอง?',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กรอกรหัสเพื่อเพิ่มคูปองเข้าบัญชีของคุณ',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponCodeController,
                  enabled: !_isClaimingCoupon,
                  textCapitalization: TextCapitalization.characters,
                  onSubmitted: (_) => _claimCoupon(),
                  decoration: InputDecoration(
                    hintText: 'กรอกรหัสคูปอง',
                    prefixIcon: const Icon(Icons.confirmation_number_outlined),
                    filled: true,
                    fillColor: AppColors.cream,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isClaimingCoupon ? null : _claimCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isClaimingCoupon
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('เพิ่มคูปอง'),
                ),
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
  Widget _buildSummary({
    required int total,
    required int available,
    required int used,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.red, AppColors.redDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_rounded,
                color: AppColors.goldLight,
                size: 27,
              ),
              SizedBox(width: 10),
              Text(
                'คูปองส่วนลดของคุณ',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              _summaryItem('ทั้งหมด', total),
              _summaryItem('พร้อมใช้', available),
              _summaryItem('ใช้แล้ว', used),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, int value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Filters
  // ========================================
  Widget _buildFilters() {
    final filters = ['ทั้งหมด', 'พร้อมใช้งาน', 'ใช้แล้ว / ใช้ไม่ได้'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(filters.length, (index) {
        final selected = _selectedFilter == index;

        return ChoiceChip(
          label: Text(filters[index]),
          selected: selected,
          onSelected: (_) {
            setState(() {
              _selectedFilter = index;
            });
          },
          selectedColor: AppColors.redDark,
          backgroundColor: AppColors.white,
          labelStyle: TextStyle(
            color: selected ? AppColors.ink : AppColors.inkMuted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(color: selected ? AppColors.red : AppColors.border),
        );
      }),
    );
  }

  // ========================================
  // Empty
  // ========================================
  Widget _buildEmpty() {
    final message = _selectedFilter == 1
        ? 'ไม่มีคูปองที่พร้อมใช้งาน'
        : _selectedFilter == 2
        ? 'ไม่มีคูปองในหมวดนี้'
        : 'คุณยังไม่ได้รับคูปอง';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.local_offer_outlined,
            color: AppColors.inkMuted,
            size: 60,
          ),

          const SizedBox(height: 15),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'เมื่อได้รับคูปองจากแอดมิน '
            'คูปองจะแสดงที่หน้านี้',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
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
              'ไม่สามารถโหลดคูปองได้',
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
}

// ==========================================
// COUPON CARD
// ==========================================
class _CouponCard extends StatelessWidget {
  final CustomerCouponModel coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          // Coupon Main
          Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.local_offer,
                        color: AppColors.goldLight,
                        size: 21,
                      ),

                      const SizedBox(height: 4),

                      Text(
                        coupon.discountLabel,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coupon.code,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _discountDescription(),
                        style: const TextStyle(
                          color: AppColors.goldText,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _statusBadge(color),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.divider, height: 1),

          // Coupon Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _detailRow(
                  'ยอดซื้อขั้นต่ำ',
                  '฿${coupon.minOrderAmount.toStringAsFixed(2)}',
                ),

                if (coupon.discountType == 'percent' &&
                    coupon.maxDiscountAmount != null) ...[
                  const SizedBox(height: 10),
                  _detailRow(
                    'ส่วนลดสูงสุด',
                    '฿${coupon.maxDiscountAmount!.toStringAsFixed(2)}',
                  ),
                ],

                const SizedBox(height: 10),

                _detailRow('เริ่มใช้งาน', _formatDate(coupon.startDateTime)),

                const SizedBox(height: 10),

                _detailRow('หมดอายุ', _formatDate(coupon.endDateTime)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Discount Description
  // ========================================
  String _discountDescription() {
    if (coupon.discountType == 'percent') {
      return 'ส่วนลด ${coupon.discountLabel} '
          'จากยอดสั่งซื้อ';
    }

    return 'ลดราคา ${coupon.discountLabel}';
  }

  // ========================================
  // Status Badge
  // ========================================
  Widget _statusBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        coupon.statusLabel,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ========================================
  // Detail Row
  // ========================================
  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ),

        const SizedBox(width: 10),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // Status Color
  // ========================================
  Color _statusColor() {
    if (coupon.isAvailable) {
      return AppColors.success;
    }

    if (coupon.isUsed || coupon.isExpired) {
      return Colors.redAccent;
    }

    if (coupon.isNotStarted) {
      return AppColors.gold;
    }

    return AppColors.inkMuted;
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

    return '$day/$month/$year';
  }
}
