const express = require('express');
const router = express.Router();

const {
    createCoupon,
    getAllCoupons,
    getCouponById,
    updateCoupon,
    deleteCoupon
} = require('../controller/coupon_controller');

const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Admin: Create coupon
router.post('/', verifyToken, verifyAdmin, createCoupon);

// Admin: View all coupons
router.get('/all', verifyToken, verifyAdmin, getAllCoupons);

// Admin: View coupon by ID
router.get('/:id', verifyToken, verifyAdmin, getCouponById);

// Admin: Update coupon
router.put('/:id', verifyToken, verifyAdmin, updateCoupon);

// Admin: Delete coupon (Soft Delete)
router.delete('/:id', verifyToken, verifyAdmin, deleteCoupon);

module.exports = router;
