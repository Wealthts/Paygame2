class CouponModel {
  final int couponId;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;
  final int? useLimit;
  final int useCount;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String? createdAt;

  const CouponModel({
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.useLimit,
    required this.useCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    this.createdAt,
  });

  factory CouponModel.fromJson(Map<String, dynamic> json) {
    return CouponModel(
      couponId: int.parse(json['coupon_id'].toString()),
      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: double.parse(json['discount_value'].toString()),
      minOrderAmount: double.parse((json['min_order_amount'] ?? 0).toString()),
      maxDiscountAmount: json['max_discount_amount'] == null
          ? null
          : double.parse(json['max_discount_amount'].toString()),
      useLimit: json['use_limit'] == null
          ? null
          : int.parse(json['use_limit'].toString()),
      useCount: int.parse((json['use_count'] ?? 0).toString()),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      isActive: int.parse((json['is_active'] ?? 0).toString()) == 1,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get discountLabel {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    return '฿${discountValue.toStringAsFixed(2)}';
  }

  String get usageLabel {
    if (useLimit == null) {
      return '$useCount / ไม่จำกัด';
    }
    return '$useCount / $useLimit';
  }
}
