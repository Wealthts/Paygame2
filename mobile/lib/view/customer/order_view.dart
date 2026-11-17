import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mobile/core/app_colors.dart';

import 'package:mobile/model/game_model.dart';
import 'package:mobile/model/package_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/order_service.dart';
import 'package:mobile/service/point_service.dart';
import 'package:mobile/service/user_coupon_service.dart';
import 'package:mobile/view/customer/payment_view.dart';

class CustomerOrderView extends StatefulWidget {
  final GameModel game;
  final PackageModel package;

  const CustomerOrderView({
    super.key,
    required this.game,
    required this.package,
  });

  @override
  State<CustomerOrderView> createState() => _CustomerOrderViewState();
}

class _CustomerOrderViewState extends State<CustomerOrderView> {
  final _formKey = GlobalKey<FormState>();
  final _playerUidController = TextEditingController();
  final _serverCodeController = TextEditingController();

  late Future<List<CustomerCouponModel>> _couponsFuture;
  late Future<int> _pointsFuture;
  final _spentPointsController = TextEditingController(text: '0');
  int _selectedSpentPoints = 0;
  int? _pointBalance;
  double _selectedCouponDiscount = 0;
  static const double _pointValueBaht = 0.1;
  int? _selectedCouponId;
  bool _isSubmitting = false;
  String? _errorMessage;

  int? _createdOrderId;
  double _createdTotal = 0;
  double _createdCouponDiscount = 0;
  double _createdDiscountAmount = 0;
  double _createdPointDiscount = 0;
  int _createdSpentPoints = 0;
  String _createdStatus = 'Pending';

  @override
  void initState() {
    super.initState();

    _loadCoupons();
    _loadPoints();
  }

  @override
  void dispose() {
    _playerUidController.dispose();
    _serverCodeController.dispose();
    _spentPointsController.dispose();
    super.dispose();
  }

  // ========================================
  // Load Customer Coupons
  // ========================================
  void _loadCoupons() {
    _couponsFuture = context.read<UserCouponService>().getMyCoupons();
  }

  // ========================================
  // Load Customer Point Balance
  // ========================================
  void _loadPoints() {
    _pointsFuture = _fetchPointBalance();
  }

  Future<int> _fetchPointBalance() async {
    final pointService = context.read<PointService>();
    final balance = await pointService.getMyPoints();

    if (!mounted) {
      return balance;
    }

    final safeBalance = math.max(0, balance);
    final amountAfterCoupon = math.max(
      0.0,
      widget.package.price - _selectedCouponDiscount,
    );
    final maxPointsByPrice = math.max(0, (amountAfterCoupon * 10).floor());
    final maxAllowedPoints = math.min(safeBalance, maxPointsByPrice);
    final selectedPoints = math.min(_selectedSpentPoints, maxAllowedPoints);

    setState(() {
      _pointBalance = safeBalance;
      _selectedSpentPoints = selectedPoints;
      _spentPointsController.text = selectedPoints.toString();
    });
    return safeBalance;
  }

  // ========================================
  // Get Eligible Coupons
  // ========================================
  List<CustomerCouponModel> _getEligibleCoupons(
    List<CustomerCouponModel> coupons,
  ) {
    return coupons.where((coupon) {
      return coupon.isAvailable &&
          widget.package.price >= coupon.minOrderAmount;
    }).toList();
  }

  // ========================================
  // Get Selected Coupon
  // ========================================
  CustomerCouponModel? _findSelectedCoupon(List<CustomerCouponModel> coupons) {
    for (final coupon in coupons) {
      if (coupon.couponId == _selectedCouponId &&
          coupon.isAvailable &&
          widget.package.price >= coupon.minOrderAmount) {
        return coupon;
      }
    }

    return null;
  }

  // ========================================
  // Calculate Coupon Discount Preview
  // ========================================
  double _calculateCouponDiscount(CustomerCouponModel coupon) {
    final price = widget.package.price;
    double discount = 0;

    if (coupon.discountType == 'fixed') {
      discount = coupon.discountValue;
    } else if (coupon.discountType == 'percent') {
      discount = price * coupon.discountValue / 100;

      final maximum = coupon.maxDiscountAmount;

      if (maximum != null && discount > maximum) {
        discount = maximum;
      }
    }

    if (discount > price) {
      discount = price;
    }

    if (discount < 0) {
      discount = 0;
    }

    return double.parse(discount.toStringAsFixed(2));
  }

  // ========================================
  // Submit Order
  // ========================================
  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCouponId = _selectedCouponId;
    final selectedSpentPoints = _selectedSpentPoints;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await context.read<OrderService>().createOrder(
        packageId: widget.package.packageId,
        playerUid: _playerUidController.text.trim(),
        serverCode: _serverCodeController.text.trim(),
        couponId: selectedCouponId,
        spentPoints: selectedSpentPoints,
      );

      // อ่าน Order ID
      final orderId = int.tryParse(response['order_id']?.toString() ?? '');
      if (orderId == null || orderId <= 0) {
        throw const FormatException('ไม่พบหมายเลขคำสั่งซื้อจากเซิร์ฟเวอร์');
      }

      // อ่านยอดชำระ
      final total =
          double.tryParse(response['total_amount']?.toString() ?? '') ??
          widget.package.price;
      // อ่านส่วนลดคูปอง
      final couponDiscount =
          double.tryParse(response['coupon_discount']?.toString() ?? '') ?? 0;
      // อ่านส่วนลดจากแต้ม
      final pointDiscount =
          double.tryParse(response['point_discount']?.toString() ?? '') ?? 0;
      // อ่านจำนวนแต้มที่ใช้จริงจาก Backend
      final spentPoints =
          int.tryParse(response['spent_points']?.toString() ?? '') ?? 0;
      // อ่านส่วนลดรวม
      final discountAmount =
          double.tryParse(response['discount_amount']?.toString() ?? '') ??
          (couponDiscount + pointDiscount);
      if (!mounted) return;

      setState(() {
        _createdOrderId = orderId;
        _createdTotal = total;
        _createdCouponDiscount = couponDiscount;
        _createdPointDiscount = pointDiscount;
        _createdSpentPoints = spentPoints;
        _createdDiscountAmount = discountAmount;
        _createdStatus = response['status']?.toString() ?? 'Pending';
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _errorMessage = _getErrorMessage(error);
      });
    }
  }

  // ========================================
  // Error Message
  // ========================================
  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      final message = error.message.toLowerCase();

      if (error.statusCode == 400) {
        if (message.contains('coupon')) {
          return 'คูปองนี้ไม่สามารถใช้งานได้แล้ว '
              'กรุณาเลือกคูปองอื่นหรือลองใหม่';
        }
        if (message.contains('order amount')) {
          return 'ยอดซื้อไม่ถึงขั้นต่ำของคูปอง';
        }
        if (message.contains('server')) {
          return 'กรุณาตรวจสอบ Server ID';
        }
        if (message.contains('insufficient points')) {
          return 'แต้มสะสมของคุณไม่เพียงพอ '
              'กรุณาปรับจำนวนแต้มที่ต้องการใช้';
        }
        if (message.contains('point discount')) {
          return 'จำนวนแต้มที่ใช้มากเกินยอดเงินที่เหลือ '
              'หลังหักส่วนลดคูปอง';
        }
        return 'ข้อมูลคำสั่งซื้อไม่ถูกต้อง '
            'กรุณาตรวจสอบ UID และข้อมูลที่กรอก';
      }

      if (error.statusCode == 401) {
        return 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่';
      }
      if (error.statusCode == 403) {
        return 'บัญชีผู้ใช้งานนี้ไม่สามารถสร้างคำสั่งซื้อได้';
      }
      if (error.statusCode == 404) {
        return 'ไม่พบแพ็กเกจที่เลือก '
            'หรือแพ็กเกจถูกปิดใช้งานแล้ว';
      }
      if (error.statusCode == 409) {
        return 'ไม่สามารถสร้างคำสั่งซื้อได้ '
            'กรุณาตรวจสอบแพ็กเกจหรือคูปองอีกครั้ง';
      }
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }
    return 'ไม่สามารถสร้างคำสั่งซื้อได้ '
        'กรุณาลองใหม่อีกครั้ง';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        foregroundColor: AppColors.white,
        title: Text(
          _createdOrderId == null
              ? 'ยืนยันคำสั่งซื้อ'
              : 'สร้างคำสั่งซื้อสำเร็จ',
        ),
      ),
      body: SafeArea(
        child: _createdOrderId == null
            ? _buildOrderForm()
            : _buildSuccessView(),
      ),
    );
  }

  // ========================================
  // Order Form
  // ========================================
  Widget _buildOrderForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildPackageSummary(),
          const SizedBox(height: 26),
          const Text(
            'ข้อมูลผู้เล่น',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'กรอกข้อมูลผู้เล่นให้ถูกต้องก่อนยืนยันคำสั่งซื้อ',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          const Text(
            'Player UID',
            style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),

          TextFormField(
            controller: _playerUidController,
            maxLength: 100,
            keyboardType: TextInputType.text,
            textInputAction: widget.game.requiresServer
                ? TextInputAction.next
                : TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(color: AppColors.ink),
            decoration: _inputDecoration(
              hint: 'กรอก Player UID',
              icon: Icons.person_outline,
            ),
            validator: (value) {
              final uid = value?.trim() ?? '';
              if (uid.isEmpty) {
                return 'กรุณากรอก Player UID';
              }
              if (uid.length > 100) {
                return 'Player UID ต้องไม่เกิน 100 ตัวอักษร';
              }
              return null;
            },
          ),

          if (widget.game.uidPattern.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'รูปแบบ UID: ${widget.game.uidPattern}',
              style: const TextStyle(color: AppColors.goldText, fontSize: 12),
            ),
          ],

          if (widget.game.requiresServer) ...[
            const SizedBox(height: 22),
            const Text(
              'Server ID / Server Code',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _serverCodeController,
              maxLength: 100,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(color: AppColors.ink),
              decoration: _inputDecoration(
                hint: 'กรอก Server ID',
                icon: Icons.dns_outlined,
              ),
              validator: (value) {
                final serverCode = value?.trim() ?? '';
                if (serverCode.isEmpty) {
                  return 'กรุณากรอก Server ID';
                }
                if (serverCode.length > 100) {
                  return 'Server ID ต้องไม่เกิน 100 ตัวอักษร';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 28),

          // Coupon Selection
          const Text(
            'คูปองส่วนลด',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),
          _buildCouponSection(),
          const SizedBox(height: 20),
          _buildPointSection(),
          const SizedBox(height: 24),
          _buildPriceSummary(),

          if (_errorMessage != null) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitOrder,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shopping_cart_checkout),
              label: Text(
                _isSubmitting ? 'กำลังสร้างคำสั่งซื้อ...' : 'ยืนยันคำสั่งซื้อ',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            'เมื่อยืนยันคำสั่งซื้อ คูปองที่เลือกจะถูกใช้ตามเงื่อนไข '
            'และคำสั่งซื้อจะเริ่มต้นด้วยสถานะ Pending',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Coupon Section
  // ========================================
  Widget _buildCouponSection() {
    return FutureBuilder<List<CustomerCouponModel>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _couponMessage(
            icon: Icons.hourglass_top,
            message: 'กำลังโหลดคูปองของคุณ...',
          );
        }

        if (snapshot.hasError) {
          return _couponMessage(
            icon: Icons.info_outline,
            message:
                'ไม่สามารถโหลดคูปองได้ '
                'คุณยังสามารถสร้างคำสั่งซื้อโดยไม่ใช้คูปอง',
          );
        }

        final coupons = snapshot.data ?? [];
        final eligibleCoupons = _getEligibleCoupons(coupons);

        if (eligibleCoupons.isEmpty) {
          final hasCoupons = coupons.isNotEmpty;

          return _couponMessage(
            icon: Icons.local_offer_outlined,
            message: hasCoupons
                ? 'ไม่มีคูปองที่เข้าเงื่อนไขยอดซื้อของแพ็กเกจนี้'
                : 'คุณยังไม่มีคูปองที่สามารถใช้ได้',
          );
        }

        final selectedCoupon = _findSelectedCoupon(eligibleCoupons);
        final selectedId = selectedCoupon?.couponId;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_offer, color: AppColors.goldLight),
                  SizedBox(width: 9),
                  Text(
                    'เลือกคูปองที่ต้องการใช้',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                initialValue: selectedId,
                isExpanded: true,
                dropdownColor: AppColors.creamDeep,
                decoration: _inputDecoration(
                  hint: 'เลือกคูปอง',
                  icon: Icons.confirmation_number_outlined,
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text(
                      'ไม่ใช้คูปอง',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                  ...eligibleCoupons.map(
                    (coupon) => DropdownMenuItem<int>(
                      value: coupon.couponId,
                      child: Text(
                        '${coupon.code} - ลด ${coupon.discountLabel}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        CustomerCouponModel? coupon;

                        if (value != null) {
                          coupon = eligibleCoupons.firstWhere(
                            (item) => item.couponId == value,
                          );
                        }

                        final couponDiscount = coupon == null
                            ? 0.0
                            : _calculateCouponDiscount(coupon);

                        final amountAfterCoupon = math.max(
                          0.0,
                          widget.package.price - couponDiscount,
                        );

                        final maxPointsByPrice = math.max(
                          0,
                          (amountAfterCoupon * 10).floor(),
                        );

                        final availableBalance =
                            _pointBalance ?? maxPointsByPrice;

                        final maxAllowedPoints = math.min(
                          availableBalance,
                          maxPointsByPrice,
                        );

                        final nextPoints = math.min(
                          _selectedSpentPoints,
                          maxAllowedPoints,
                        );

                        setState(() {
                          _selectedCouponId = value;
                          _selectedCouponDiscount = couponDiscount;
                          _selectedSpentPoints = nextPoints;
                          _spentPointsController.text = nextPoints.toString();
                          _errorMessage = null;
                        });
                      },
              ),

              if (selectedCoupon != null) ...[
                const SizedBox(height: 16),
                _buildSelectedCoupon(selectedCoupon),
              ],
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // Point Selection Section
  // ========================================
  Widget _buildPointSection() {
    return FutureBuilder<int>(
      future: _pointsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _couponMessage(
            icon: Icons.hourglass_top,
            message: 'กำลังโหลดแต้มสะสมของคุณ...',
          );
        }

        if (snapshot.hasError) {
          return _couponMessage(
            icon: Icons.info_outline,
            message:
                'ไม่สามารถโหลดแต้มสะสมได้ '
                'คุณยังสามารถสร้างคำสั่งซื้อโดยไม่ใช้แต้ม',
          );
        }

        final balance = math.max(0, snapshot.data ?? 0);

        final amountAfterCoupon = math.max(
          0.0,
          widget.package.price - _selectedCouponDiscount,
        );

        // 10 แต้ม = 1 บาท
        // จำกัดแต้มไม่ให้ส่วนลดเกินยอดหลังหักคูปอง
        final maxPointsByPrice = math.max(0, (amountAfterCoupon * 10).floor());

        final maxPoints = math.min(balance, maxPointsByPrice);

        final selectedPoints = _selectedSpentPoints.clamp(0, maxPoints).toInt();

        final pointDiscount = selectedPoints * _pointValueBaht;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.stars, color: AppColors.goldLight),
                  SizedBox(width: 9),
                  Text(
                    'ใช้แต้มสะสม',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'แต้มคงเหลือของคุณ',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                  Text(
                    '$balance แต้ม',
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text(
                'จำนวนแต้มที่ต้องการใช้',
                style: TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _spentPointsController,
                enabled: !_isSubmitting && maxPoints > 0,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: AppColors.ink, fontSize: 16),
                decoration:
                    _inputDecoration(
                      hint: 'กรอกจำนวนแต้ม',
                      icon: Icons.stars_outlined,
                    ).copyWith(
                      suffixText: 'แต้ม',
                      suffixStyle: const TextStyle(color: AppColors.inkMuted),
                    ),
                onChanged: (value) {
                  final parsedPoints = int.tryParse(value) ?? 0;

                  final nextPoints = math.min(parsedPoints, maxPoints);

                  // ป้องกันการใส่แต้มเกินจำนวนที่ใช้ได้
                  if (parsedPoints > maxPoints) {
                    final correctedText = maxPoints.toString();

                    _spentPointsController.value = TextEditingValue(
                      text: correctedText,
                      selection: TextSelection.collapsed(
                        offset: correctedText.length,
                      ),
                    );
                  }

                  setState(() {
                    _selectedSpentPoints = nextPoints;
                    _errorMessage = null;
                  });
                },
              ),

              const SizedBox(height: 10),

              Text(
                'ใช้ได้สูงสุด $maxPoints แต้ม',
                style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ส่วนลดจากแต้ม',
                    style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
                  ),
                  Text(
                    '-฿${pointDiscount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'อัตราการแลก: 10 แต้ม = 1 บาท '
                'ระบบจะตรวจสอบยอดแต้มอีกครั้งก่อนสร้างคำสั่งซื้อ',
                style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // Selected Coupon Details
  // ========================================
  Widget _buildSelectedCoupon(CustomerCouponModel coupon) {
    final discount = _calculateCouponDiscount(coupon);
    final netAmount = widget.package.price - discount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'เลือกคูปอง ${coupon.code} แล้ว',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _priceRow(
            'ส่วนลดโดยประมาณ',
            '-฿${discount.toStringAsFixed(2)}',
            valueColor: AppColors.success,
          ),

          const SizedBox(height: 8),

          _priceRow(
            'ยอดหลังหักส่วนลด',
            '฿${netAmount.toStringAsFixed(2)}',
            valueColor: AppColors.goldText,
          ),

          const SizedBox(height: 9),

          const Text(
            'ยอดจริงจะคำนวณและตรวจสอบอีกครั้งโดยเซิร์ฟเวอร์',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Coupon Message
  // ========================================
  Widget _couponMessage({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.goldText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.inkMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================
  // Package Summary
  // ========================================
  Widget _buildPackageSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'แพ็กเกจที่เลือก',
            style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),

          const SizedBox(height: 12),

          Text(
            widget.game.gameName,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            widget.package.packageName,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
          ),

          const Divider(color: AppColors.divider, height: 28),

          _priceRow(
            'ราคาแพ็กเกจ',
            '฿${widget.package.price.toStringAsFixed(2)}',
            valueColor: AppColors.goldText,
          ),
        ],
      ),
    );
  }

  // ========================================
  // Price Summary
  // ========================================
  Widget _buildPriceSummary() {
    return FutureBuilder<List<CustomerCouponModel>>(
      future: _couponsFuture,
      builder: (context, snapshot) {
        final selectedCoupon = snapshot.hasData
            ? _findSelectedCoupon(snapshot.data!)
            : null;

        final couponDiscount = selectedCoupon == null
            ? 0.0
            : _calculateCouponDiscount(selectedCoupon);

        final pointDiscount = _selectedSpentPoints * _pointValueBaht;

        final total = math.max(
          0.0,
          widget.package.price - couponDiscount - pointDiscount,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.creamDeep,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _priceRow(
                'ราคาแพ็กเกจ',
                '฿${widget.package.price.toStringAsFixed(2)}',
              ),

              if (couponDiscount > 0) ...[
                const SizedBox(height: 12),

                _priceRow(
                  'ส่วนลดคูปอง',
                  '-฿${couponDiscount.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
              ],

              if (pointDiscount > 0) ...[
                const SizedBox(height: 12),

                _priceRow(
                  'ส่วนลดจากแต้ม ($_selectedSpentPoints แต้ม)',
                  '-฿${pointDiscount.toStringAsFixed(2)}',
                  valueColor: AppColors.success,
                ),
              ],

              const Divider(color: AppColors.border, height: 26),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดสุทธิโดยประมาณ',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    '฿${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.goldText,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ========================================
  // Price Row
  // ========================================
  Widget _priceRow(
    String label,
    String value, {
    Color valueColor = AppColors.inkMuted,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ),

        const SizedBox(width: 12),

        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ========================================
  // Success View
  // ========================================
  Widget _buildSuccessView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 82),
            const SizedBox(height: 20),
            const Text(
              'สร้างคำสั่งซื้อสำเร็จ',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ระบบบันทึกคำสั่งซื้อของคุณเรียบร้อยแล้ว',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 14),
            ),

            const SizedBox(height: 26),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _resultRow('Order ID', '#$_createdOrderId'),
                  const Divider(color: AppColors.divider, height: 26),
                  _resultRow('เกม', widget.game.gameName),
                  const SizedBox(height: 12),
                  _resultRow('แพ็กเกจ', widget.package.packageName),
                  const SizedBox(height: 12),
                  _resultRow('Player UID', _playerUidController.text.trim()),
                  if (widget.game.requiresServer) ...[
                    const SizedBox(height: 12),
                    _resultRow('Server ID', _serverCodeController.text.trim()),
                  ],

                  if (_createdCouponDiscount > 0) ...[
                    const SizedBox(height: 12),
                    _resultRow(
                      'ส่วนลดคูปอง',
                      '-฿${_createdCouponDiscount.toStringAsFixed(2)}',
                      valueColor: AppColors.success,
                    ),
                  ],

                  if (_createdSpentPoints > 0) ...[
                    const SizedBox(height: 12),
                    _resultRow('แต้มที่ใช้', '$_createdSpentPoints แต้ม'),
                    const SizedBox(height: 8),
                    _resultRow(
                      'ส่วนลดจากแต้ม',
                      '-฿${_createdPointDiscount.toStringAsFixed(2)}',
                      valueColor: AppColors.success,
                    ),
                  ],
                  const Divider(color: AppColors.divider, height: 26),
                  _resultRow(
                    'ราคาเดิม',
                    '฿${widget.package.price.toStringAsFixed(2)}',
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    'ส่วนลดรวม',
                    '-฿${_createdDiscountAmount.toStringAsFixed(2)}',
                    valueColor: AppColors.success,
                  ),
                  const Divider(color: AppColors.divider, height: 26),
                  _resultRow(
                    'ยอดคำสั่งซื้อ',
                    '฿${_createdTotal.toStringAsFixed(2)}',
                    valueColor: AppColors.goldText,
                  ),
                  const SizedBox(height: 12),
                  _resultRow(
                    'สถานะ',
                    _createdStatus,
                    valueColor: AppColors.gold,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),
            const Text(
              'คำสั่งซื้อยังอยู่ในสถานะ Pending '
              'กรุณาดำเนินการชำระเงินในขั้นตอนถัดไป',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => CustomerPaymentView(
                        orderId: _createdOrderId!,
                        amount: _createdTotal,
                        gameName: widget.game.gameName,
                        packageName: widget.package.packageName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.payment),
                label: const Text('แจ้งการชำระเงิน'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.border),
                ),
                child: const Text('กลับไปหน้าแพ็กเกจ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================
  // Result Row
  // ========================================
  Widget _resultRow(
    String label,
    String value, {
    Color valueColor = Colors.white,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.inkMuted, fontSize: 13),
          ),
        ),

        const SizedBox(width: 12),

        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // Input Decoration
  // ========================================
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.inkMuted),
      prefixIcon: Icon(icon, color: AppColors.inkMuted),
      filled: true,
      fillColor: AppColors.white,
      counterStyle: const TextStyle(color: AppColors.inkMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.red),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}
