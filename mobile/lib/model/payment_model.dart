class PaymentModel {
  final int paymentId;
  final int orderId;
  final String transactionRef;
  final String method;
  final double amount;
  final String status;

  final String? gameName;
  final String? packageName;

  final DateTime? createdAt;
  final DateTime? paidAt;

  const PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.transactionRef,
    required this.method,
    required this.amount,
    required this.status,
    this.gameName,
    this.packageName,
    this.createdAt,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();

      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;

      return DateTime.tryParse(value.toString());
    }

    String? toNullableString(dynamic value) {
      if (value == null) return null;

      return value.toString();
    }

    return PaymentModel(
      paymentId: toInt(json['payment_id']),
      orderId: toInt(json['order_id']),
      transactionRef: json['transaction_ref']?.toString() ?? '',
      method: json['method']?.toString() ?? '',
      amount: toDouble(json['amount']),
      status: json['status']?.toString() ?? 'Pending',

      gameName: toNullableString(json['game_name_snapshot']),

      packageName: toNullableString(json['package_name_snapshot']),

      createdAt: toDate(json['created_at']),
      paidAt: toDate(json['paid_at']),
    );
  }
}
