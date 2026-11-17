
const db = require('../db_config');

function parsePositiveId(value) {
    const id = Number(value);
    return Number.isInteger(id) && id > 0 ? id : null;
}

function createError(statusCode, message) {
    const error = new Error(message);
    error.statusCode = statusCode;
    return error;
}

// GET /api/admin/user-coupons/all
// ดูคูปองทั้งหมดที่ถูกมอบให้สมาชิก
async function getAllUserCoupons(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                uc.user_coupon_id,
                uc.user_id,
                uc.coupon_id,
                uc.used_at,
                u.username,
                u.display_name,
                u.email,
                c.code,
                c.discount_type,
                c.discount_value,
                c.min_order_amount,
                c.max_discount_amount,
                c.start_date,
                c.end_date,
                c.is_active AS coupon_is_active
             FROM user_coupons uc
             INNER JOIN users u
                ON uc.user_id = u.user_id
             INNER JOIN coupons c
                ON uc.coupon_id = c.coupon_id
             ORDER BY uc.user_coupon_id DESC`
        );

        return res.status(200).json({
            user_coupons: rows
        });
    } catch (error) {
        console.error('Get All User Coupons Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// GET /api/admin/user-coupons/users
// รายชื่อสมาชิกที่ยังเปิดใช้งาน ไม่รวม Admin
async function getAvailableUsers(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                user_id,
                username,
                display_name,
                email
             FROM users
             WHERE role = 'user'
               AND is_active = 1
             ORDER BY display_name ASC`
        );

        return res.status(200).json({
            users: rows
        });
    } catch (error) {
        console.error('Get Available Users Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// POST /api/admin/user-coupons
// มอบคูปองให้สมาชิก
async function assignCoupon(req, res) {
    const userId = parsePositiveId(req.body.user_id);
    const couponId = parsePositiveId(req.body.coupon_id);

    if (!userId || !couponId) {
        return res.status(400).json({
            message: 'Invalid user_id or coupon_id'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // ตรวจสอบและล็อกสมาชิก
        const [users] = await connection.query(
            `SELECT user_id
             FROM users
             WHERE user_id = ?
               AND role = 'user'
               AND is_active = 1
             FOR UPDATE`,
            [userId]
        );

        if (users.length === 0) {
            throw createError(
                404,
                'User not found or inactive'
            );
        }

        // ตรวจสอบและล็อกคูปอง
        const [coupons] = await connection.query(
            `SELECT
                coupon_id,
                is_active,
                (end_date >= NOW()) AS not_expired,
                (use_limit IS NULL OR use_count < use_limit) AS has_quota
             FROM coupons
             WHERE coupon_id = ?
             FOR UPDATE`,
            [couponId]
        );

        if (coupons.length === 0) {
            throw createError(404, 'Coupon not found');
        }

        const coupon = coupons[0];

        if (Number(coupon.is_active) !== 1) {
            throw createError(400, 'Coupon is inactive');
        }

        if (Number(coupon.not_expired) !== 1) {
            throw createError(400, 'Coupon has expired');
        }

        if (Number(coupon.has_quota) !== 1) {
            throw createError(
                400,
                'Coupon usage limit has been reached'
            );
        }

        // ป้องกันการมอบคูปองใบเดิมซ้ำในขณะที่ใบเดิมยังไม่ได้ใช้
        const [duplicates] = await connection.query(
            `SELECT user_coupon_id
             FROM user_coupons
             WHERE user_id = ?
               AND coupon_id = ?
               AND used_at IS NULL
             LIMIT 1`,
            [userId, couponId]
        );

        if (duplicates.length > 0) {
            throw createError(
                409,
                'User already has an unused copy of this coupon'
            );
        }

        const [result] = await connection.query(
            `INSERT INTO user_coupons (
                user_id,
                coupon_id,
                used_at
             )
             VALUES (?, ?, NULL)`,
            [userId, couponId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'Coupon assigned successfully',
            user_coupon_id: result.insertId
        });
    } catch (error) {
        if (transactionStarted && connection) {
            await connection.rollback();
            transactionStarted = false;
        }

        console.error('Assign Coupon Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });
    } finally {
        if (connection) {
            connection.release();
        }
    }
}

module.exports = {
    getAllUserCoupons,
    getAvailableUsers,
    assignCoupon
};
