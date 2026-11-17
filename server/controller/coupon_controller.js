const db = require('../db_config');

function toTinyInt(value) {
    if (value === true || value === 1 || value === '1') return 1;
    if (value === false || value === 0 || value === '0') return 0;
    return null;
}

// Create coupon
async function createCoupon(req, res) {
    try {
        const {
            code, discount_type,
            discount_value, min_order_amount,
            max_discount_amount, use_limit,
            start_date, end_date,
            is_active
        } = req.body || {};

        const couponCode = typeof code === 'string'? code.trim().toUpperCase(): '';
        const discountValue = Number(discount_value);
        
        const minOrderAmount =
            min_order_amount === undefined ||
                min_order_amount === null ||
                min_order_amount === ''
                ? 0
                : Number(min_order_amount);

        const maxDiscountAmount =
            max_discount_amount === undefined ||
                max_discount_amount === null ||
                max_discount_amount === ''
                ? null
                : Number(max_discount_amount);

        const useLimit =
            use_limit === undefined ||
                use_limit === null ||
                use_limit === ''
                ? null
                : Number(use_limit);

        const activeStatus = is_active === undefined
            ? 1
            : toTinyInt(is_active);

        // Validate coupon data
        if (
            couponCode === '' || couponCode.length > 50 ||
            !['fixed', 'percent'].includes(discount_type) ||
            !Number.isFinite(discountValue) || discountValue <= 0 ||
            (discount_type === 'percent' && discountValue > 100) ||
            !Number.isFinite(minOrderAmount) || minOrderAmount < 0 ||
            (maxDiscountAmount !== null &&
                (!Number.isFinite(maxDiscountAmount) ||
                    maxDiscountAmount <= 0)) ||
            (useLimit !== null &&
                (!Number.isInteger(useLimit) || useLimit <= 0)) ||
            typeof start_date !== 'string' || typeof end_date !== 'string' ||
            Number.isNaN(new Date(start_date).getTime()) ||
            Number.isNaN(new Date(end_date).getTime()) ||
            new Date(start_date) > new Date(end_date) ||
            ![0, 1].includes(activeStatus)
        ) {
            return res.status(400).json({
                message: 'Invalid coupon data'
            });
        }

        // Insert coupon
        const [result] = await db.promise().query(
            `INSERT INTO coupons
            (
                code,
                discount_type,
                discount_value,
                min_order_amount,
                max_discount_amount,
                use_limit,
                start_date,
                end_date,
                is_active
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                couponCode,
                discount_type,
                discountValue,
                minOrderAmount,
                maxDiscountAmount,
                useLimit,
                start_date,
                end_date,
                activeStatus
            ]
        );

        return res.status(201).json({
            message: 'Coupon created successfully',
            coupon_id: result.insertId
        });

    } catch (error) {
        console.error('Create Coupon Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Coupon code already exists'
            });
        }

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// View all coupons
async function getAllCoupons(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT *
             FROM coupons
             ORDER BY created_at DESC`
        );

        return res.status(200).json({
            coupons: rows
        });

    } catch (error) {
        console.error('Get All Coupons Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// View coupon by ID
async function getCouponById(req, res) {
    try {
        const couponId = Number(req.params.id);

        if (!Number.isInteger(couponId) || couponId <= 0) {
            return res.status(400).json({
                message: 'Invalid coupon ID'
            });
        }

        const [rows] = await db.promise().query(
            `SELECT *
             FROM coupons
             WHERE coupon_id = ?`,
            [couponId]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                message: 'Coupon not found'
            });
        }

        return res.status(200).json(rows[0]);

    } catch (error) {
        console.error('Get Coupon By ID Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Update coupon
async function updateCoupon(req, res) {
    try {
        const couponId = Number(req.params.id);

        // 1. Validate couponId first
        if (!Number.isInteger(couponId) || couponId <= 0) {
            return res.status(400).json({
                message: 'Invalid coupon ID'
            });
        }

        const {
            code,
            discount_type,
            discount_value,
            min_order_amount,
            max_discount_amount,
            use_limit,
            start_date,
            end_date,
            is_active
        } = req.body || {};

        // 2. Ensure all required fields are provided for Full Update (PUT)
        if (
            code === undefined ||
            discount_type === undefined ||
            discount_value === undefined ||
            discount_value === null ||
            discount_value === '' ||
            min_order_amount === undefined ||
            min_order_amount === null ||
            min_order_amount === '' ||
            max_discount_amount === undefined ||
            use_limit === undefined ||
            start_date === undefined ||
            end_date === undefined ||
            is_active === undefined
        ) {
            return res.status(400).json({
                message: 'Missing required fields for full update'
            });
        }

        // 3. Parse & validate values
        const couponCode = typeof code === 'string'
            ? code.trim().toUpperCase()
            : '';

        const discountValue = Number(discount_value);
        const minOrderAmount = Number(min_order_amount);

        const maxDiscountAmount =
            max_discount_amount === undefined ||
                max_discount_amount === null ||
                max_discount_amount === ''
                ? null
                : Number(max_discount_amount);

        const useLimit =
            use_limit === undefined ||
                use_limit === null ||
                use_limit === ''
                ? null
                : Number(use_limit);

        const activeStatus = toTinyInt(is_active);

        if (
            !Number.isInteger(couponId) ||
            couponId <= 0 ||
            couponCode === '' ||
            couponCode.length > 50 ||
            !['fixed', 'percent'].includes(discount_type) ||
            !Number.isFinite(discountValue) ||
            discountValue <= 0 ||
            (discount_type === 'percent' && discountValue > 100) ||
            !Number.isFinite(minOrderAmount) ||
            minOrderAmount < 0 ||
            (maxDiscountAmount !== null &&
                (!Number.isFinite(maxDiscountAmount) ||
                    maxDiscountAmount <= 0)) ||
            (useLimit !== null &&
                (!Number.isInteger(useLimit) || useLimit <= 0)) ||
            typeof start_date !== 'string' ||
            typeof end_date !== 'string' ||
            Number.isNaN(new Date(start_date).getTime()) ||
            Number.isNaN(new Date(end_date).getTime()) ||
            new Date(start_date) > new Date(end_date) ||
            ![0, 1].includes(activeStatus)
        ) {
            return res.status(400).json({
                message: 'Invalid coupon data'
            });
        }

        // 4. Check existing coupon
        const [coupons] = await db.promise().query(
            `SELECT coupon_id, use_count
             FROM coupons
             WHERE coupon_id = ?`,
            [couponId]
        );

        if (coupons.length === 0) {
            return res.status(404).json({
                message: 'Coupon not found'
            });
        }

        // Cannot set usage limit below current usage
        if (
            useLimit !== null &&
            useLimit < Number(coupons[0].use_count)
        ) {
            return res.status(400).json({
                message: 'Use limit cannot be less than current use count'
            });
        }

        // Update coupon
        await db.promise().query(
            `UPDATE coupons
             SET code = ?,
                 discount_type = ?,
                 discount_value = ?,
                 min_order_amount = ?,
                 max_discount_amount = ?,
                 use_limit = ?,
                 start_date = ?,
                 end_date = ?,
                 is_active = ?
             WHERE coupon_id = ?`,
            [
                couponCode,
                discount_type,
                discountValue,
                minOrderAmount,
                maxDiscountAmount,
                useLimit,
                start_date,
                end_date,
                activeStatus,
                couponId
            ]
        );

        return res.status(200).json({
            message: 'Coupon updated successfully'
        });

    } catch (error) {
        console.error('Update Coupon Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Coupon code already exists'
            });
        }

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Delete coupon (Soft Delete)
async function deleteCoupon(req, res) {
    try {
        const couponId = Number(req.params.id);

        if (!Number.isInteger(couponId) || couponId <= 0) {
            return res.status(400).json({
                message: 'Invalid coupon ID'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE coupons
             SET is_active = 0
             WHERE coupon_id = ?
             AND is_active = 1`,
            [couponId]
        );

        if (result.affectedRows === 0) {
            const [rows] = await db.promise().query(
                `SELECT coupon_id
                 FROM coupons
                 WHERE coupon_id = ?`,
                [couponId]
            );

            if (rows.length === 0) {
                return res.status(404).json({
                    message: 'Coupon not found'
                });
            }

            return res.status(200).json({
                message: 'Coupon already inactive'
            });
        }

        return res.status(200).json({
            message: 'Coupon deactivated successfully'
        });

    } catch (error) {
        console.error('Delete Coupon Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

module.exports = {
    createCoupon,
    getAllCoupons,
    getCouponById,
    updateCoupon,
    deleteCoupon
};
