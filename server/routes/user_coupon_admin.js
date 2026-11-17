
const express = require('express');
const router = express.Router();

const userCouponController = require(
    '../controller/user_coupon_admin_controller'
);

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// Admin: ดูคูปองของสมาชิกทั้งหมด
router.get(
    '/all',
    verifyToken,
    verifyAdmin,
    userCouponController.getAllUserCoupons
);

// Admin: ดูรายชื่อสมาชิกสำหรับมอบคูปอง
router.get(
    '/users',
    verifyToken,
    verifyAdmin,
    userCouponController.getAvailableUsers
);

// Admin: มอบคูปองให้สมาชิก
router.post(
    '/',
    verifyToken,
    verifyAdmin,
    userCouponController.assignCoupon
);

module.exports = router;
