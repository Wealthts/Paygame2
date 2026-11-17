import 'package:mobile/model/admin/user_admin_model.dart';

List<Map<String, dynamic>> _readRows(dynamic value) {
  if (value is! List) return [];

  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

class UserDetailsModel {
  final AdminUserModel user;

  final int orderCount;
  final int paymentCount;
  final double paidAmount;
  final int pointBalance;
  final int receiptCount;
  final int couponCount;

  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> pointTransactions;
  final List<Map<String, dynamic>> receipts;
  final List<Map<String, dynamic>> userCoupons;

  const UserDetailsModel({
    required this.user,
    required this.orderCount,
    required this.paymentCount,
    required this.paidAmount,
    required this.pointBalance,
    required this.receiptCount,
    required this.couponCount,
    required this.orders,
    required this.payments,
    required this.pointTransactions,
    required this.receipts,
    required this.userCoupons,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    final userJson = Map<String, dynamic>.from(json['user'] as Map);

    final summary = Map<String, dynamic>.from(json['summary'] as Map);

    return UserDetailsModel(
      user: AdminUserModel.fromJson(userJson),

      orderCount: int.parse((summary['order_count'] ?? 0).toString()),

      paymentCount: int.parse((summary['payment_count'] ?? 0).toString()),

      paidAmount: double.parse((summary['paid_amount'] ?? 0).toString()),

      pointBalance: int.parse((summary['point_balance'] ?? 0).toString()),

      receiptCount: int.parse((summary['receipt_count'] ?? 0).toString()),

      couponCount: int.parse((summary['coupon_count'] ?? 0).toString()),

      orders: _readRows(json['orders']),
      payments: _readRows(json['payments']),
      pointTransactions: _readRows(json['point_transactions']),
      receipts: _readRows(json['receipts']),
      userCoupons: _readRows(json['user_coupons']),
    );
  }
}
