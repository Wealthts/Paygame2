class PointModel {
  final int pointTransactionId;
  final int userId;
  final int? orderId;
  final String eventKey;
  final String type;
  final int pointsDelta;
  final String? username;
  final String? displayName;
  final DateTime? createdAt;

  const PointModel({
    required this.pointTransactionId,
    required this.userId,
    this.orderId,
    required this.eventKey,
    required this.type,
    required this.pointsDelta,
    this.username,
    this.displayName,
    this.createdAt,
  });

  factory PointModel.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    DateTime? toDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return PointModel(
      pointTransactionId: toInt(json['point_transaction_id']),
      userId: toInt(json['user_id']),
      orderId: json['order_id'] == null ? null : toInt(json['order_id']),
      eventKey: json['event_key']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      pointsDelta: toInt(json['points_delta']),
      username: json['username']?.toString(),
      displayName: json['display_name']?.toString(),
      createdAt: toDate(json['created_at']),
    );
  }
}
