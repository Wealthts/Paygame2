class UserOptionModel {
  final int userId;
  final String username;
  final String displayName;
  final String email;

  const UserOptionModel({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.email,
  });

  factory UserOptionModel.fromJson(Map<String, dynamic> json) {
    return UserOptionModel(
      userId: int.parse(json['user_id'].toString()),
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  String get label => '$displayName (@$username)';
}

class UserCouponModel {
  final int userCouponId;
  final int userId;
  final int couponId;

  final String username;
  final String displayName;
  final String email;

  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;

  final String startDate;
  final String endDate;
  final String? usedAt;
  final bool couponIsActive;

  const UserCouponModel({
    required this.userCouponId,
    required this.userId,
    required this.couponId,
    required this.username,
    required this.displayName,
    required this.email,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.startDate,
    required this.endDate,
    required this.usedAt,
    required this.couponIsActive,
  });

  factory UserCouponModel.fromJson(Map<String, dynamic> json) {
    return UserCouponModel(
      userCouponId: int.parse(json['user_coupon_id'].toString()),
      userId: int.parse(json['user_id'].toString()),
      couponId: int.parse(json['coupon_id'].toString()),

      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',

      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: double.parse(json['discount_value'].toString()),
      minOrderAmount: double.parse((json['min_order_amount'] ?? 0).toString()),
      maxDiscountAmount: json['max_discount_amount'] == null
          ? null
          : double.parse(json['max_discount_amount'].toString()),

      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      usedAt: json['used_at']?.toString(),
      couponIsActive:
          int.parse((json['coupon_is_active'] ?? 0).toString()) == 1,
    );
  }

  bool get isUsed => usedAt != null;

  String get discountLabel {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}%';
    }

    return '฿${discountValue.toStringAsFixed(2)}';
  }
}

// ==========================================
// CUSTOMER COUPON MODEL
// ==========================================
class CustomerCouponModel {
  final int userCouponId;
  final int couponId;

  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderAmount;
  final double? maxDiscountAmount;

  final String startDate;
  final String endDate;
  final String? usedAt;
  final bool couponIsActive;

  const CustomerCouponModel({
    required this.userCouponId,
    required this.couponId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.startDate,
    required this.endDate,
    required this.usedAt,
    required this.couponIsActive,
  });

  factory CustomerCouponModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();

      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;

      final text = value?.toString().toLowerCase();

      return text == '1' || text == 'true';
    }

    return CustomerCouponModel(
      userCouponId: parseInt(json['user_coupon_id']),
      couponId: parseInt(json['coupon_id']),
      code: json['code']?.toString() ?? '',
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: parseDouble(json['discount_value']),
      minOrderAmount: parseDouble(json['min_order_amount']),
      maxDiscountAmount: json['max_discount_amount'] == null
          ? null
          : parseDouble(json['max_discount_amount']),
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      usedAt: json['used_at']?.toString(),
      couponIsActive: parseBool(json['is_active']),
    );
  }

  // ========================================
  // Date Helpers
  // ========================================
  DateTime? get startDateTime {
    return DateTime.tryParse(startDate);
  }

  DateTime? get endDateTime {
    return DateTime.tryParse(endDate);
  }

  bool get isUsed {
    return usedAt != null && usedAt!.trim().isNotEmpty;
  }

  bool get isExpired {
    final end = endDateTime;

    return end != null && DateTime.now().isAfter(end);
  }

  bool get isNotStarted {
    final start = startDateTime;

    return start != null && DateTime.now().isBefore(start);
  }

  // ========================================
  // Availability
  // ========================================
  bool get isAvailable {
    return couponIsActive &&
        !isUsed &&
        !isExpired &&
        !isNotStarted &&
        startDateTime != null &&
        endDateTime != null;
  }

  String get statusLabel {
    if (isUsed) return 'ใช้แล้ว';
    if (!couponIsActive) return 'ปิดใช้งาน';
    if (startDateTime == null || endDateTime == null) {
      return 'ตรวจสอบช่วงเวลาไม่ได้';
    }
    if (isNotStarted) return 'ยังไม่เริ่มใช้';
    if (isExpired) return 'หมดอายุ';

    return 'พร้อมใช้งาน';
  }

  // ========================================
  // Discount Label
  // ========================================
  String get discountLabel {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}%';
    }

    return '฿${discountValue.toStringAsFixed(2)}';
  }
}
