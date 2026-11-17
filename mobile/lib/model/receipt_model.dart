class ReceiptModel {
  final int receiptId;
  final int orderId;
  final String receiptNumber;
  final DateTime? issuedAt;

  // ข้อมูลเพิ่มเติมสำหรับหน้าลูกค้า
  final String? gameName;
  final String? packageName;
  final double? totalAmount;

  const ReceiptModel({
    required this.receiptId,
    required this.orderId,
    required this.receiptNumber,
    this.issuedAt,
    this.gameName,
    this.packageName,
    this.totalAmount,
  });

  factory ReceiptModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return ReceiptModel(
      receiptId: toInt(json['receipt_id']),
      orderId: toInt(json['order_id']),
      receiptNumber: json['receipt_number']?.toString() ?? '',
      issuedAt: toDate(json['issued_at']),
      gameName: json['game_name_snapshot']?.toString(),
      packageName: json['package_name_snapshot']?.toString(),
      totalAmount: toDouble(json['total_amount']),
    );
  }
}
