class OrderModel {
  final int orderId;
  final int userId;
  final int packageId;

  final String playerUid;
  final String serverCode;
  final String gameName;
  final String packageName;
  final String status;
  final String? paymentStatus;

  final double originalPrice;
  final double discountAmount;
  final double totalAmount;
  final double couponDiscount;
  final double feeAmount;

  final int spentPoints;

  final String? username;
  final String? displayName;
  final String? couponCode;
  final DateTime? createdAt;
  final DateTime? completedAt;

  const OrderModel({
    required this.orderId,
    required this.userId,
    required this.packageId,
    required this.playerUid,
    required this.serverCode,
    required this.gameName,
    required this.packageName,
    required this.status,
    required this.paymentStatus,
    required this.originalPrice,
    required this.discountAmount,
    required this.totalAmount,
    required this.couponDiscount,
    required this.feeAmount,
    required this.spentPoints,
    this.username,
    this.displayName,
    this.couponCode,
    this.createdAt,
    this.completedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? toNullableString(dynamic value) {
      if (value == null) return null;
      return value.toString();
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return OrderModel(
      orderId: toInt(json['order_id']),
      userId: toInt(json['user_id']),
      packageId: toInt(json['package_id']),
      playerUid: json['player_uid']?.toString() ?? '',
      serverCode: json['server_code']?.toString() ?? '',
      gameName: json['game_name_snapshot']?.toString() ?? '',
      packageName: json['package_name_snapshot']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      paymentStatus: toNullableString(json['payment_status']),
      originalPrice: toDouble(json['original_price']),
      discountAmount: toDouble(json['discount_amount']),
      totalAmount: toDouble(json['total_amount']),
      couponDiscount: toDouble(json['coupon_discount']),
      feeAmount: toDouble(json['fee_amount']),
      spentPoints: toInt(json['spent_points']),
      username: toNullableString(json['username']),
      displayName: toNullableString(json['display_name']),
      couponCode: toNullableString(json['coupon_code_snapshot']),
      createdAt: toDate(json['created_at']),
      completedAt: toDate(json['completed_at']),
    );
  }
}
