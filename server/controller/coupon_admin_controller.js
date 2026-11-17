
const db = require('../db_config');

function parseCouponId(value) {
    const id = Number(value);
    return Number.isInteger(id) && id > 0 ? id : null;
}

function normalizeDateTime(value) {
    if (typeof value !== 'string') return null;


    const input = value.trim().replace('T', ' ');

    // let input = value.trim().replace('T', ' ');
    // input = input.replace(/(Z|[+-]\d{2}:\d{2})$/, '');
    // input = input.replace(/\.\d+$/, '');

    const match = input.match(
        /^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/
    );

    if (!match) return null;

    const [, y, mo, d, h, mi, s] = match.map(Number);
    const date = new Date(Date.UTC(y, mo - 1, d, h, mi, s));

    if (
        date.getUTCFullYear() !== y ||
        date.getUTCMonth() !== mo - 1 ||
        date.getUTCDate() !== d ||
        date.getUTCHours() !== h ||
        date.getUTCMinutes() !== mi ||
        date.getUTCSeconds() !== s
    ) {
        return null;
    }

    return input;
}

function validateCoupon(body) {
    const code = String(body.code || '').trim().toUpperCase();
    const discountType = body.discount_type;
    const discountValue = Number(body.discount_value);
    const minOrderAmount = Number(body.min_order_amount ?? 0);

    const maxDiscountAmount =
        body.max_discount_amount === null ||
            body.max_discount_amount === undefined ||
            body.max_discount_amount === ''
            ? null
            : Number(body.max_discount_amount);

    const useLimit =
        body.use_limit === null ||
            body.use_limit === undefined ||
            body.use_limit === ''
            ? null
            : Number(body.use_limit);

    const startDate = normalizeDateTime(body.start_date);
    const endDate = normalizeDateTime(body.end_date);

    if (!code || code.length > 50) {
        return { error: 'กรุณาระบุรหัสคูปองไม่เกิน 50 ตัวอักษร' };
    }

    if (!['fixed', 'percent'].includes(discountType)) {
        return { error: 'ประเภทส่วนลดไม่ถูกต้อง' };
    }

    if (
        !Number.isFinite(discountValue) ||
        discountValue <= 0 ||
        (discountType === 'percent' && discountValue > 100)
    ) {
        return { error: 'มูลค่าส่วนลดไม่ถูกต้อง' };
    }

    if (
        !Number.isFinite(minOrderAmount) ||
        minOrderAmount < 0
    ) {
        return { error: 'ยอดสั่งซื้อขั้นต่ำไม่ถูกต้อง' };
    }

    if (
        maxDiscountAmount !== null &&
        (!Number.isFinite(maxDiscountAmount) || maxDiscountAmount <= 0)
    ) {
        return { error: 'ส่วนลดสูงสุดไม่ถูกต้อง' };
    }

    if (
        useLimit !== null &&
        (!Number.isInteger(useLimit) || useLimit <= 0)
    ) {
        return { error: 'จำนวนครั้งที่ใช้ได้ต้องเป็นจำนวนเต็มมากกว่า 0' };
    }

    if (!startDate || !endDate || startDate >= endDate) {
        return { error: 'วันเริ่มต้นหรือวันสิ้นสุดไม่ถูกต้อง' };
    }

    return {
        data: {
            code,
            discount_type: discountType,
            discount_value: discountValue,
            min_order_amount: minOrderAmount,
            max_discount_amount: maxDiscountAmount,
            use_limit: useLimit,
            start_date: startDate,
            end_date: endDate
        }
    };
}

// GET /api/admin/coupons/all
async function getAllCoupons(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT *
             FROM coupons
             ORDER BY created_at DESC, coupon_id DESC`
        );

        return res.status(200).json({ coupons: rows });
    } catch (error) {
        console.error('Get All Coupons Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// POST /api/admin/coupons
async function createCoupon(req, res) {
    try {
        const validation = validateCoupon(req.body);

        if (validation.error) {
            return res.status(400).json({
                message: validation.error
            });
        }

        const c = validation.data;

        const [result] = await db.promise().query(
            `INSERT INTO coupons (
                code,
                discount_type,
                discount_value,
                min_order_amount,
                max_discount_amount,
                use_limit,
                start_date,
                end_date,
                is_active
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)`,
            [
                c.code,
                c.discount_type,
                c.discount_value,
                c.min_order_amount,
                c.max_discount_amount,
                c.use_limit,
                c.start_date,
                c.end_date
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

// PUT /api/admin/coupons/:id
async function updateCoupon(req, res) {
    try {
        const couponId = parseCouponId(req.params.id);

        if (!couponId) {
            return res.status(400).json({
                message: 'Invalid coupon ID'
            });
        }

        const validation = validateCoupon(req.body);

        if (validation.error) {
            return res.status(400).json({
                message: validation.error
            });
        }

        const c = validation.data;

        const [existing] = await db.promise().query(
            `SELECT coupon_id, use_count
             FROM coupons
             WHERE coupon_id = ?`,
            [couponId]
        );

        if (existing.length === 0) {
            return res.status(404).json({
                message: 'Coupon not found'
            });
        }

        if (
            c.use_limit !== null &&
            c.use_limit < Number(existing[0].use_count)
        ) {
            return res.status(400).json({
                message: 'จำนวนครั้งที่กำหนดต้องไม่น้อยกว่าจำนวนที่ใช้ไปแล้ว'
            });
        }

        await db.promise().query(
            `UPDATE coupons
             SET code = ?,
                 discount_type = ?,
                 discount_value = ?,
                 min_order_amount = ?,
                 max_discount_amount = ?,
                 use_limit = ?,
                 start_date = ?,
                 end_date = ?
             WHERE coupon_id = ?`,
            [
                c.code,
                c.discount_type,
                c.discount_value,
                c.min_order_amount,
                c.max_discount_amount,
                c.use_limit,
                c.start_date,
                c.end_date,
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

// PATCH /api/admin/coupons/:id/status
async function updateCouponStatus(req, res) {
    try {
        const couponId = parseCouponId(req.params.id);
        const isActive = Number(req.body.is_active);

        if (!couponId || ![0, 1].includes(isActive)) {
            return res.status(400).json({
                message: 'Invalid coupon ID or status'
            });
        }

        const [result] = await db.promise().query(
            `UPDATE coupons
             SET is_active = ?
             WHERE coupon_id = ?`,
            [isActive, couponId]
        );

        if (result.affectedRows === 0) {
            return res.status(404).json({
                message: 'Coupon not found'
            });
        }

        return res.status(200).json({
            message: 'Coupon status updated successfully'
        });
    } catch (error) {
        console.error('Update Coupon Status Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

module.exports = {
    getAllCoupons,
    createCoupon,
    updateCoupon,
    updateCouponStatus
};
