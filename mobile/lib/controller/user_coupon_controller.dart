import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/coupon_model.dart';
import 'package:mobile/model/user_coupon_model.dart';
import 'package:mobile/service/coupon_service.dart';
import 'package:mobile/service/user_coupon_service.dart';

class UserCouponController extends ChangeNotifier {
  final UserCouponService userCouponService;
  final CouponService couponService;

  UserCouponController(this.userCouponService, this.couponService);

  List<UserCouponModel> userCoupons = [];
  List<UserOptionModel> users = [];
  List<CouponModel> coupons = [];

  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  int get totalAssignments => userCoupons.length;

  int get unusedAssignments => userCoupons.where((item) => !item.isUsed).length;

  int get usedAssignments => userCoupons.where((item) => item.isUsed).length;

  List<CouponModel> get availableCoupons =>
      coupons.where((coupon) => coupon.isActive).toList();

  Future<void> loadData({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      notifyListeners();
    }

    errorMessage = null;

    try {
      userCoupons = await userCouponService.getAllUserCoupons();

      users = await userCouponService.getAvailableUsers();

      coupons = await couponService.getAllCoupons();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> assignCoupon({
    required int userId,
    required int couponId,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    try {
      await userCouponService.assignCoupon(userId: userId, couponId: couponId);

      await loadData(showLoading: false);
    } catch (e) {
      errorMessage = e.toString();
      rethrow;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
