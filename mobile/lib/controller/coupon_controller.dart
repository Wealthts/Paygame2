import 'package:material_ui/material_ui.dart';

import '../model/coupon_model.dart';
import '../service/coupon_service.dart';

class CouponController extends ChangeNotifier {
  final CouponService couponService;

  CouponController(this.couponService);

  List<CouponModel> coupons = [];

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  int get totalCoupons => coupons.length;

  int get activeCoupons => coupons.where((coupon) => coupon.isActive).length;

  int get inactiveCoupons => coupons.where((coupon) => !coupon.isActive).length;

  Future<void> loadCoupons({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    errorMessage = null;

    try {
      coupons = await couponService.getAllCoupons();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveCoupon({
    int? couponId,
    required Map<String, dynamic> body,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (couponId == null) {
        await couponService.createCoupon(body);
      } else {
        await couponService.updateCoupon(couponId, body);
      }

      await loadCoupons(showLoading: false);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> setCouponStatus(int couponId, bool isActive) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await couponService.updateCouponStatus(couponId, isActive);

      await loadCoupons(showLoading: false);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
