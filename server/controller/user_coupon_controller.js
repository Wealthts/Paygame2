
const db = require('../db_config');

// ตรวจสอบว่า ID เป็นจำนวนเต็มบวกหรือไม่
function isValidId(value) {
    const id = Number(value);
    return Number.isInteger(id) && id > 0;
}

// 1. Admin มอบคูปองให้ผู้ใช้
const createUserCoupon = async (req, res) => {
    const body = req.body || {};

    const userId = Number(body.user_id);
    const couponId = Number(body.coupon_id);

    if (
        !Number.isInteger(userId) || userId <= 0 ||
        !Number.isInteger(couponId) || couponId <= 0
    ) {
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

        // 1. Lock user
        const [users] = await connection.query(
            `SELECT user_id, is_active
             FROM users
             WHERE user_id = ?
             FOR UPDATE`,
            [userId]
        );

        if (users.length === 0 || Number(users[0].is_active) !== 1) {
            const error = new Error('User not found or inactive');
            error.statusCode = 404;
            throw error;
        }

        // 2. Lock coupon
        const [coupons] = await connection.query(
            `SELECT
                coupon_id,
                is_active,
                use_limit,
                use_count
            FROM coupons
            WHERE coupon_id = ?
            AND end_date >= NOW()
            FOR UPDATE`,
            [couponId]
        );

        if (coupons.length === 0) {
            const error = new Error('Coupon not found or expired');
            error.statusCode = 404;
            throw error;
        }

        const coupon = coupons[0];

        // 3. Check coupon availability
        if (Number(coupon.is_active) !== 1) {
            const error = new Error('Coupon is inactive');
            error.statusCode = 409;
            throw error;
        }

        if (
            coupon.use_limit !== null &&
            Number(coupon.use_count) >= Number(coupon.use_limit)
        ) {
            const error = new Error('Coupon usage limit has been reached');
            error.statusCode = 409;
            throw error;
        }

        // 4. Check unused coupon already assigned
        const [existing] = await connection.query(
            `SELECT user_coupon_id
             FROM user_coupons
             WHERE user_id = ?
             AND coupon_id = ?
             AND used_at IS NULL
             LIMIT 1`,
            [userId, couponId]
        );

        if (existing.length > 0) {
            const error = new Error('User already has this unused coupon');
            error.statusCode = 409;
            throw error;
        }

        // 5. Assign coupon
        const [result] = await connection.query(
            `INSERT INTO user_coupons (
                user_id,
                coupon_id
            )
            VALUES (?, ?)`,
            [userId, couponId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'Coupon assigned successfully',
            user_coupon_id: result.insertId,
            user_id: userId,
            coupon_id: couponId
        });

    } catch (error) {

        if (transactionStarted && connection) await connection.rollback();

        console.error('Create User Coupon Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
};

// ผู้ใช้รับคูปองด้วยรหัสด้วยตัวเอง
const claimCouponByCode = async (req, res) => {
    const userId = Number(req.user && req.user.user_id);
    const code = typeof (req.body || {}).code === 'string'
        ? req.body.code.trim().toUpperCase()
        : '';

    if (!Number.isInteger(userId) || userId <= 0 || !code || code.length > 50) {
        return res.status(400).json({ message: 'กรุณากรอกรหัสคูปองให้ถูกต้อง' });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();
        await connection.beginTransaction();
        transactionStarted = true;

        const [coupons] = await connection.query(
            `SELECT coupon_id, is_active, use_limit, use_count
             FROM coupons
             WHERE code = ?
               AND start_date <= NOW()
               AND end_date >= NOW()
             LIMIT 1
             FOR UPDATE`,
            [code]
        );

        if (coupons.length === 0) {
            const error = new Error('ไม่พบรหัสคูปอง หรือคูปองหมดอายุ/ยังไม่เริ่มใช้งาน');
            error.statusCode = 404;
            throw error;
        }

        const coupon = coupons[0];
        if (Number(coupon.is_active) !== 1) {
            const error = new Error('คูปองนี้ปิดใช้งานอยู่');
            error.statusCode = 409;
            throw error;
        }

        if (coupon.use_limit !== null && Number(coupon.use_count) >= Number(coupon.use_limit)) {
            const error = new Error('คูปองนี้ถูกใช้ครบจำนวนแล้ว');
            error.statusCode = 409;
            throw error;
        }

        const [existing] = await connection.query(
            `SELECT user_coupon_id
             FROM user_coupons
             WHERE user_id = ? AND coupon_id = ? AND used_at IS NULL
             LIMIT 1`,
            [userId, coupon.coupon_id]
        );

        if (existing.length > 0) {
            const error = new Error('คุณมีคูปองนี้อยู่แล้ว');
            error.statusCode = 409;
            throw error;
        }

        const [result] = await connection.query(
            `INSERT INTO user_coupons (user_id, coupon_id) VALUES (?, ?)`,
            [userId, coupon.coupon_id]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'เพิ่มคูปองเข้าบัญชีแล้ว',
            user_coupon_id: result.insertId,
            coupon_id: coupon.coupon_id
        });
    } catch (error) {
        if (transactionStarted && connection) await connection.rollback();
        console.error('Claim Coupon Error:', error);
        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'ไม่สามารถเพิ่มคูปองได้ กรุณาลองใหม่'
        });
    } finally {
        if (connection) connection.release();
    }
};


// 2. Admin ดูคูปองของผู้ใช้ทั้งหมด
const getAllUserCoupons = (req, res) => {
    const sql = `
        SELECT
            uc.user_coupon_id,
            uc.user_id,
            u.username,
            u.display_name,
            uc.coupon_id,
            c.code,
            c.discount_type,
            c.discount_value,
            c.min_order_amount,
            c.max_discount_amount,
            c.start_date,
            c.end_date,
            c.is_active,
            uc.used_at
        FROM user_coupons uc
        JOIN users u ON uc.user_id = u.user_id
        JOIN coupons c ON uc.coupon_id = c.coupon_id
        ORDER BY uc.user_coupon_id DESC
    `;

    db.query(sql, (err, result) => {
        if (err) {
            return res.status(500).json({
                message: 'Database error',
                error: err.message
            });
        }

        return res.status(200).json(result);
    });
};

// 3. ผู้ใช้ดูคูปองของตัวเอง
const getMyCoupons = (req, res) => {
    const user_id = req.user.user_id;

    const sql = `
        SELECT
            uc.user_coupon_id,
            uc.coupon_id,
            c.code,
            c.discount_type,
            c.discount_value,
            c.min_order_amount,
            c.max_discount_amount,
            c.start_date,
            c.end_date,
            c.is_active,
            uc.used_at
        FROM user_coupons uc
        JOIN coupons c ON uc.coupon_id = c.coupon_id
        WHERE uc.user_id = ?
        ORDER BY uc.user_coupon_id DESC
    `;

    db.query(sql, [user_id], (err, result) => {
        if (err) {
            return res.status(500).json({
                message: 'Database error',
                error: err.message
            });
        }

        return res.status(200).json(result);
    });
};

// 4. ดูรายละเอียดคูปองของผู้ใช้ตาม ID
const getUserCouponById = (req, res) => {
    const userCouponId = Number(req.params.id);

    if (!isValidId(userCouponId)) {
        return res.status(400).json({
            message: 'Invalid user_coupon_id'
        });
    }

    const sql = `
        SELECT
            uc.user_coupon_id,
            uc.user_id,
            u.username,
            uc.coupon_id,
            c.code,
            c.discount_type,
            c.discount_value,
            c.min_order_amount,
            c.max_discount_amount,
            c.start_date,
            c.end_date,
            c.is_active,
            uc.used_at
        FROM user_coupons uc
        JOIN users u ON uc.user_id = u.user_id
        JOIN coupons c ON uc.coupon_id = c.coupon_id
        WHERE uc.user_coupon_id = ?
    `;

    db.query(sql, [userCouponId], (err, result) => {
        if (err) {
            return res.status(500).json({
                message: 'Database error',
                error: err.message
            });
        }

        if (result.length === 0) {
            return res.status(404).json({
                message: 'User coupon not found'
            });
        }

        const coupon = result[0];

        // ผู้ใช้ทั่วไปดูได้เฉพาะคูปองของตัวเอง
        if (
            req.user.role !== 'admin' &&
            Number(coupon.user_id) !== Number(req.user.user_id)
        ) {
            return res.status(403).json({
                message: 'Access denied'
            });
        }

        return res.status(200).json(coupon);
    });
};

// 5. Admin ยกเลิกการมอบคูปองที่ยังไม่ได้ใช้
const deleteUserCoupon = async (req, res) => {
    const userCouponId = Number(req.params.id);

    if (!Number.isInteger(userCouponId) || userCouponId <= 0) {
        return res.status(400).json({
            message: 'Invalid user_coupon_id'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Find user ID first
        const [initialRows] = await connection.query(
            `SELECT user_id
             FROM user_coupons
             WHERE user_coupon_id = ?`,
            [userCouponId]
        );

        if (initialRows.length === 0) {
            const error = new Error('User coupon not found');
            error.statusCode = 404;
            throw error;
        }

        const userId = initialRows[0].user_id;

        // 2. Lock user
        const [users] = await connection.query(
            `SELECT user_id
             FROM users
             WHERE user_id = ?
             FOR UPDATE`,
            [userId]
        );

        if (users.length === 0) {
            const error = new Error('User not found');
            error.statusCode = 404;
            throw error;
        }

        // 3. Lock coupon assignment
        const [rows] = await connection.query(
            `SELECT
                user_coupon_id,
                used_at
             FROM user_coupons
             WHERE user_coupon_id = ?
             AND user_id = ?
             FOR UPDATE`,
            [userCouponId, userId]
        );

        if (rows.length === 0) {
            const error = new Error('User coupon not found');
            error.statusCode = 404;
            throw error;
        }

        if (rows[0].used_at !== null) {
            const error = new Error('Cannot delete a coupon that has been used');
            error.statusCode = 400;
            throw error;
        }

        // 4. Check order reference
        const [orders] = await connection.query(
            `SELECT order_id
             FROM orders
             WHERE user_coupon_id = ?
             LIMIT 1`,
            [userCouponId]
        );

        if (orders.length > 0) {
            const error = new Error('Cannot delete a coupon referenced by an order');
            error.statusCode = 409;
            throw error;
        }

        // 5. Delete unused assignment
        await connection.query(
            `DELETE FROM user_coupons
             WHERE user_coupon_id = ?
             AND used_at IS NULL`,
            [userCouponId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'User coupon deleted successfully'
        });

    } catch (error) {

        if (transactionStarted && connection) {
            await connection.rollback();
        }

        console.error('Delete User Coupon Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
};

module.exports = {
    createUserCoupon,
    claimCouponByCode,
    getAllUserCoupons,
    getMyCoupons,
    getUserCouponById,
    deleteUserCoupon
};
