import '../model/coupon_model.dart';
import 'api_service.dart';

class CouponService {
  final ApiService api;

  CouponService(this.api);

  // Get all coupons
  Future<List<CouponModel>> getAllCoupons() async {
    final response = await api.get('/api/admin/coupons/all');

    if (response is! Map || response['coupons'] is! List) {
      throw const FormatException('Invalid coupons response');
    }

    final List<dynamic> data = response['coupons'];

    return data.map((item) {
      return CouponModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // Create coupon
  Future<void> createCoupon(Map<String, dynamic> body) async {
    await api.post('/api/admin/coupons', body: body);
  }

  // Update coupon
  Future<void> updateCoupon(int couponId, Map<String, dynamic> body) async {
    await api.put('/api/admin/coupons/$couponId', body: body);
  }

  // Enable / Disable coupon
  Future<void> updateCouponStatus(int couponId, bool isActive) async {
    await api.patch(
      '/api/admin/coupons/$couponId/status',
      body: {'is_active': isActive ? 1 : 0},
    );
  }
}
