import '../model/user_coupon_model.dart';
import 'api_service.dart';

class UserCouponService {
  final ApiService api;

  UserCouponService(this.api);

  // Get all user coupons
  Future<List<UserCouponModel>> getAllUserCoupons() async {
    final response = await api.get('/api/admin/user-coupons/all');

    if (response is! Map || response['user_coupons'] is! List) {
      throw const FormatException('Invalid user coupons response');
    }

    final List<dynamic> data = response['user_coupons'];

    return data.map((item) {
      return UserCouponModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // Get active members
  Future<List<UserOptionModel>> getAvailableUsers() async {
    final response = await api.get('/api/admin/user-coupons/users');

    if (response is! Map || response['users'] is! List) {
      throw const FormatException('Invalid users response');
    }

    final List<dynamic> data = response['users'];

    return data.map((item) {
      return UserOptionModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // ========================================
  // Get My Coupons (Customer)
  // ========================================
  Future<List<CustomerCouponModel>> getMyCoupons() async {
    final response = await api.get('/api/user-coupons/my-coupons');

    // Backend คืนค่าเป็น Array โดยตรง
    if (response is! List) {
      throw const FormatException('รูปแบบข้อมูลคูปองไม่ถูกต้อง');
    }

    return response.map((item) {
      if (item is! Map) {
        throw const FormatException('ข้อมูลคูปองไม่ถูกต้อง');
      }

      return CustomerCouponModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // Assign coupon to member
  Future<void> assignCoupon({
    required int userId,
    required int couponId,
  }) async {
    await api.post(
      '/api/admin/user-coupons',
      body: {'user_id': userId, 'coupon_id': couponId},
    );
  }
}
