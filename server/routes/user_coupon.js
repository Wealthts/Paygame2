
const express = require('express');
const router = express.Router();

const {
    createUserCoupon,
    getAllUserCoupons,
    getMyCoupons,
    getUserCouponById,
    deleteUserCoupon
} = require('../controller/user_coupon_controller');

const { verifyToken, verifyAdmin } = require('../middleware/auth');


// Admin Create coupon for user
router.post('/', verifyToken, verifyAdmin, createUserCoupon);

// Admin view all user coupons
router.get('/all', verifyToken, verifyAdmin, getAllUserCoupons);

// User view their own coupons
router.get('/my-coupons', verifyToken, getMyCoupons);

// User view a specific coupon by ID
router.get('/:id', verifyToken, getUserCouponById);

// Admin delete a user coupon by ID (only if not used)
router.delete('/:id', verifyToken, verifyAdmin, deleteUserCoupon);

module.exports = router;
