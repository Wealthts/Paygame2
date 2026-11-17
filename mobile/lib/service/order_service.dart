import 'package:mobile/model/order_model.dart';
import 'package:mobile/service/api_service.dart';

class OrderService {
  final ApiService _apiService;

  OrderService(this._apiService);

  static const String _endpoint = '/api/orders';

  // ========================================
  // Get All Orders (Admin)
  // ========================================
  Future<List<OrderModel>> getAllOrders() async {
    final response = await _apiService.get('$_endpoint/all');

    if (response is! Map || response['orders'] is! List) {
      throw const FormatException('รูปแบบข้อมูลคำสั่งซื้อไม่ถูกต้อง');
    }

    final ordersJson = response['orders'] as List;

    return ordersJson.map((item) {
      if (item is! Map) {
        throw const FormatException('ข้อมูลคำสั่งซื้อไม่ถูกต้อง');
      }

      return OrderModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ========================================
  // Get My Orders (Customer)
  // ========================================
  Future<List<OrderModel>> getMyOrders() async {
    final response = await _apiService.get('$_endpoint/my-orders');

    if (response is! Map || response['orders'] is! List) {
      throw const FormatException('รูปแบบประวัติคำสั่งซื้อไม่ถูกต้อง');
    }

    final ordersJson = response['orders'] as List;

    return ordersJson.map((item) {
      if (item is! Map) {
        throw const FormatException('ข้อมูลคำสั่งซื้อไม่ถูกต้อง');
      }

      return OrderModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ========================================
  // Cancel My Order (Customer)
  // ========================================
  Future<void> cancelMyOrder(int orderId) async {
    if (orderId <= 0) {
      throw ArgumentError('Invalid order ID');
    }

    await _apiService.delete('$_endpoint/my-orders/$orderId');
  }
  
  // ========================================
  // Create Order (Customer)
  // ========================================
  Future<Map<String, dynamic>> createOrder({
    required int packageId,
    required String playerUid,
    String serverCode = '',
    int? couponId,
    int spentPoints = 0,
  }) async {
    if (packageId <= 0) {
      throw ArgumentError('Invalid package ID');
    }
    if (couponId != null && couponId <= 0) {
      throw ArgumentError('Invalid coupon ID');
    }
    if (spentPoints < 0) {
      throw ArgumentError('Invalid spent points');
    }

    final body = <String, dynamic>{
      'package_id': packageId,
      'player_uid': playerUid.trim(),
      'server_code': serverCode.trim(),
      'coupon_id': ?couponId,
      'spent_points': spentPoints,
    };
    
    final response = await _apiService.post(_endpoint, body: body);
    if (response is! Map) {
      throw const FormatException('รูปแบบข้อมูลคำสั่งซื้อไม่ถูกต้อง');
    }
    return Map<String, dynamic>.from(response);
  }

  // ========================================
  // Update Order Status (Admin)
  // ========================================
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
  }) async {
    await _apiService.put('$_endpoint/$orderId', body: {'status': status});
  }

  // ========================================
  // Cancel Order (Admin)
  // ========================================
  Future<void> cancelOrder(int orderId) async {
    await _apiService.delete('$_endpoint/$orderId');
  }
}
