
const express = require('express');
const router = express.Router();

const couponController = require('../controller/coupon_admin_controller');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Admin: Get all coupons
router.get('/all', verifyToken, verifyAdmin, couponController.getAllCoupons);

// Admin: Create coupon
router.post('/', verifyToken, verifyAdmin, couponController.createCoupon);

// Admin: Update coupon
router.put('/:id', verifyToken, verifyAdmin, couponController.updateCoupon);

// Admin: Enable / Disable coupon
router.patch('/:id/status', verifyToken, verifyAdmin, couponController.updateCouponStatus);

module.exports = router;
