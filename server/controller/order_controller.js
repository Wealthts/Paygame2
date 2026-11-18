const db = require('../db_config');
const POINT_VALUE_BAHT = 0.1; // 10 points = 1 Baht

// ==========================================
// Helper Functions
// ==========================================
// ตรวจสอบ ID จำนวนเต็มบวก
function parsePositiveId(value) {
    if (
        typeof value === 'number' &&
        Number.isSafeInteger(value) &&
        value > 0
    ) { return value; }
    if (
        typeof value === 'string' &&
        /^\d+$/.test(value.trim())
    ) {
        const number = Number(value);
        return Number.isSafeInteger(number) && number > 0
            ? number
            : null;
    } return null;
}

// ตรวจสอบจำนวนเต็มที่ไม่น้อยกว่า 0
function parseNonNegativeInt(value) {
    if (
        typeof value === 'number' &&
        Number.isSafeInteger(value) &&
        value >= 0
    ) { return value; }

    if (
        typeof value === 'string' &&
        /^\d+$/.test(value.trim())
    ) {
        const number = Number(value);
        return Number.isSafeInteger(number) && number >= 0
            ? number
            : null;
    } return null;
}

// ==========================================
// Get All Orders (Admin)
// ==========================================
async function getAllOrders(req, res) {
    try {
        const [orders] = await db.promise().query(
            `SELECT
                orders.*,
                users.username,
                users.display_name
             FROM orders
             INNER JOIN users
                ON orders.user_id = users.user_id
             ORDER BY orders.created_at DESC`
        );

        return res.status(200).json({
            orders: orders
        });

    } catch (error) {
        console.error('Get All Orders Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Get Order By ID (Admin)
// ==========================================
async function getOrderById(req, res) {
    try {
        const orderId = parsePositiveId(req.params.id);

        if (!orderId) {
            return res.status(400).json({
                message: 'Invalid order ID'
            });
        }

        const [orders] = await db.promise().query(
            `SELECT
                orders.*,
                users.username,
                users.display_name
             FROM orders
             INNER JOIN users
                ON orders.user_id = users.user_id
             WHERE orders.order_id = ?`,
            [orderId]
        );

        if (orders.length === 0) {
            return res.status(404).json({
                message: 'Order not found'
            });
        }

        return res.status(200).json({
            order: orders[0]
        });

    } catch (error) {
        console.error('Get Order Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Get My Orders (User)
// ==========================================
async function getMyOrders(req, res) {
    try {
        const userId = parsePositiveId(req.user?.user_id);

        if (!userId) {
            return res.status(401).json({
                message: 'Invalid user'
            });
        }

        const [orders] = await db.promise().query(
            `SELECT
                o.order_id,
                o.package_id,
                o.player_uid,
                o.server_code,
                o.game_name_snapshot,
                o.package_name_snapshot,
                o.original_price,
                o.discount_amount,
                o.total_amount,
                o.status,
                o.created_at,
                o.completed_at,
                o.coupon_id,
                o.coupon_code_snapshot,
                o.spent_points,
                o.coupon_discount,
                o.fee_amount,
                p.status AS payment_status
            FROM orders o
            LEFT JOIN payments p
                ON p.order_id = o.order_id
            WHERE o.user_id = ?
            ORDER BY o.created_at DESC`,
            [userId]
        );

        return res.status(200).json({
            orders: orders
        });

    } catch (error) {
        console.error('Get My Orders Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Create Order (User)
// ==========================================
async function createOrder(req, res) {
    const body =
        req.body &&
            typeof req.body === 'object' &&
            !Array.isArray(req.body)
            ? req.body
            : {};

    const user_id = parsePositiveId(req.user?.user_id);
    const package_id = parsePositiveId(body.package_id);

    const player_uid =
        typeof body.player_uid === 'string'
            ? body.player_uid.trim()
            : '';

    const server_code =
        typeof body.server_code === 'string'
            ? body.server_code.trim()
            : '';

    const hasCoupon =
        body.coupon_id !== undefined &&
        body.coupon_id !== null &&
        body.coupon_id !== '';

    const coupon_id = hasCoupon
        ? parsePositiveId(body.coupon_id)
        : null;

    const spent_points = body.spent_points === undefined
        ? 0
        : parseNonNegativeInt(body.spent_points);

    // ตรวจสอบ User
    if (!user_id) {
        return res.status(401).json({
            message: 'Invalid user'
        });
    }

    // ตรวจสอบข้อมูล Package และ UID
    if (
        !package_id ||
        !player_uid ||
        player_uid.length > 100 ||
        typeof body.player_uid !== 'string' ||
        server_code.length > 100
    ) {
        return res.status(400).json({
            message: 'Invalid package_id, player_uid or server_code'
        });
    }

    // ตรวจสอบแต้ม
    if (spent_points === null) {
        return res.status(400).json({
            message: 'Invalid spent_points'
        });
    }

    // ตรวจสอบ Coupon ID
    if (hasCoupon && !coupon_id) {
        return res.status(400).json({
            message: 'Invalid coupon_id'
        });
    }

    let connection;
    let transactionStarted = false;

    const rejectRequest = (statusCode, message) => {
        const error = new Error(message);
        error.statusCode = statusCode;
        throw error;
    };

    try {
        // ขอ Connection
        connection = await db.promise().getConnection();
        // เริ่ม Transaction
        await connection.beginTransaction();
        transactionStarted = true;

        // ----------------------------------
        // 1. Lock User
        // ----------------------------------
        const [userRows] = await connection.query(
            `SELECT
                user_id,
                is_active
             FROM users
             WHERE user_id = ?
             FOR UPDATE`,
            [user_id]
        );

        if (userRows.length === 0) {
            rejectRequest(404, 'User not found');
        }

        if (Number(userRows[0].is_active) !== 1) {
            rejectRequest(403, 'User account is inactive');
        }

        // ----------------------------------
        // 2. Check Package and Game
        // ----------------------------------
        const [packageRows] = await connection.query(
            `SELECT
                p.package_id,
                p.package_name,
                p.price,
                p.is_active AS package_active,
                g.game_name,
                g.requires_server,
                g.is_active AS game_active
             FROM packages p
             INNER JOIN games g
                ON p.game_id = g.game_id
             WHERE p.package_id = ?
             FOR UPDATE`,
            [package_id]
        );

        if (packageRows.length === 0) {
            rejectRequest(404, 'Package not found');
        }

        const packageData = packageRows[0];

        if (
            Number(packageData.package_active) !== 1 ||
            Number(packageData.game_active) !== 1
        ) {
            rejectRequest(400, 'Package or game is inactive');
        }

        if (
            Number(packageData.requires_server) === 1 &&
            !server_code
        ) {
            rejectRequest(400, 'Server code is required');
        }

        const original_price = Number(packageData.price);

        if (
            !Number.isFinite(original_price) ||
            original_price <= 0
        ) {
            rejectRequest(409, 'Invalid package price');
        }

        // ----------------------------------
        // 3. Initialize Coupon
        // ----------------------------------
        let coupon_discount = 0;
        let coupon_code = null;
        let saved_coupon_id = null;
        let user_coupon_id = null;

        // ----------------------------------
        // 4. Check and Lock Coupon
        // ----------------------------------
        if (hasCoupon) {
            const [couponRows] = await connection.query(
                `SELECT
                    uc.user_coupon_id,
                    uc.user_id,
                    uc.coupon_id,
                    c.code,
                    c.discount_type,
                    c.discount_value,
                    c.min_order_amount,
                    c.max_discount_amount
                 FROM user_coupons uc
                 INNER JOIN coupons c
                    ON uc.coupon_id = c.coupon_id
                 WHERE uc.user_id = ?
                   AND uc.coupon_id = ?
                   AND uc.used_at IS NULL
                   AND c.is_active = 1
                   AND c.start_date <= NOW()
                   AND c.end_date >= NOW()
                   AND (
                       c.use_limit IS NULL
                       OR c.use_count < c.use_limit
                   )
                 ORDER BY uc.user_coupon_id ASC
                 LIMIT 1
                 FOR UPDATE`,
                [user_id, coupon_id]
            );

            if (couponRows.length === 0) {
                rejectRequest(
                    400,
                    'Coupon is not assigned to this user or is unavailable'
                );
            }

            const coupon = couponRows[0];

            const discount_value = Number(coupon.discount_value);
            const min_order_amount = Number(coupon.min_order_amount);

            if (
                !Number.isFinite(discount_value) ||
                discount_value <= 0 ||
                !Number.isFinite(min_order_amount) ||
                min_order_amount < 0
            ) {
                rejectRequest(409, 'Invalid coupon configuration');
            }

            if (coupon.discount_type === 'fixed') {

                coupon_discount = discount_value;

            } else if (coupon.discount_type === 'percent') {

                if (discount_value > 100) {
                    rejectRequest(409, 'Invalid coupon discount rate');
                }

                coupon_discount =
                    original_price * discount_value / 100;

                if (coupon.max_discount_amount !== null) {

                    const maxDiscount = Number(
                        coupon.max_discount_amount
                    );

                    if (
                        !Number.isFinite(maxDiscount) ||
                        maxDiscount < 0
                    ) {
                        rejectRequest(409, 'Invalid maximum coupon discount');
                    }

                    coupon_discount = Math.min(
                        coupon_discount,
                        maxDiscount
                    );
                }

            } else {
                rejectRequest(409, 'Invalid coupon type');
            }

            // ตรวจสอบยอดขั้นต่ำ
            if (original_price < min_order_amount) {
                rejectRequest(
                    400,
                    'Order amount does not meet coupon minimum'
                );
            }

            // ส่วนลดต้องไม่เกินราคา
            coupon_discount = Math.min(
                original_price,
                coupon_discount
            );

            coupon_discount = Number(
                coupon_discount.toFixed(2)
            );

            coupon_code = coupon.code;
            saved_coupon_id = coupon.coupon_id;
            user_coupon_id = coupon.user_coupon_id;
        }

        // ----------------------------------
        // 5. Calculate Discount
        // ----------------------------------
        const amount_after_coupon = Number(
            (original_price - coupon_discount).toFixed(2)
        );

        // ----------------------------------
        // 6. Check Point Balance
        // ----------------------------------
        let point_balance = 0;

        if (spent_points > 0) {

            const [balanceRows] = await connection.query(
                `SELECT
                    COALESCE(SUM(points_delta), 0) AS total_points
                 FROM point_transactions
                 WHERE user_id = ?`,
                [user_id]
            );

            point_balance = Number(
                balanceRows[0].total_points
            );

            if (
                !Number.isSafeInteger(point_balance) ||
                point_balance < 0
            ) {
                rejectRequest(409, 'Invalid point balance');
            }

            if (spent_points > point_balance) {
                rejectRequest(400, 'Insufficient points');
            }
        }

        // ----------------------------------
        // 7. Calculate Point Discount
        // ----------------------------------
        const point_discount = Number(
            (spent_points * POINT_VALUE_BAHT).toFixed(2)
        );

        if (point_discount > amount_after_coupon) {
            rejectRequest(
                400,
                'Point discount exceeds remaining order amount'
            );
        }

        // ----------------------------------
        // 8. Calculate Final Amount
        // ----------------------------------
        const discount_amount = Number(
            (coupon_discount + point_discount).toFixed(2)
        );

        const total_amount = Number(
            (original_price - discount_amount).toFixed(2)
        );

        // ----------------------------------
        // 9. Insert Order
        // ----------------------------------
        const [orderResult] = await connection.query(
            `INSERT INTO orders (
                user_id,
                package_id,
                player_uid,
                server_code,
                game_name_snapshot,
                package_name_snapshot,
                original_price,
                discount_amount,
                total_amount,
                status,
                coupon_id,
                user_coupon_id,
                coupon_code_snapshot,
                spent_points,
                coupon_discount,
                fee_amount
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
                user_id,
                package_id,
                player_uid,
                server_code,
                packageData.game_name,
                packageData.package_name,
                original_price,
                discount_amount,
                total_amount,
                'Pending',
                saved_coupon_id,
                user_coupon_id,
                coupon_code,
                spent_points,
                coupon_discount,
                0
            ]
        );

        const order_id = orderResult.insertId;

        // ----------------------------------
        // 10. Mark Coupon as Used
        // ----------------------------------
        if (hasCoupon) {
            const [usedResult] = await connection.query(
                `UPDATE user_coupons
                 SET used_at = NOW()
                 WHERE user_coupon_id = ?
                   AND used_at IS NULL`,
                [user_coupon_id]
            );

            if (usedResult.affectedRows !== 1) {
                rejectRequest(409, 'Coupon has already been used');
            }

            // Increase Coupon Usage Count
            const [countResult] = await connection.query(
                `UPDATE coupons
                 SET use_count = use_count + 1
                 WHERE coupon_id = ?
                   AND is_active = 1
                   AND (
                       use_limit IS NULL
                       OR use_count < use_limit
                   )`,
                [saved_coupon_id]
            );

            if (countResult.affectedRows !== 1) {
                rejectRequest(
                    409,
                    'Coupon usage limit has been reached'
                );
            }
        }

        // ----------------------------------
        // 11. Record Point Spending
        // ----------------------------------
        if (spent_points > 0) {
            const event_key = `ORDER_${order_id}_SPEND`;

            await connection.query(
                `INSERT INTO point_transactions (
                    user_id,
                    order_id,
                    event_key,
                    type,
                    points_delta
                )
                VALUES (?, ?, ?, ?, ?)`,
                [
                    user_id,
                    order_id,
                    event_key,
                    'Spend',
                    -spent_points
                ]
            );
        }

        // ----------------------------------
        // 12. Commit Transaction
        // ----------------------------------
        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'Order created successfully',
            order_id: order_id,
            original_price: original_price,
            coupon_discount: coupon_discount,
            point_discount: point_discount,
            spent_points: spent_points,
            discount_amount: discount_amount,
            total_amount: total_amount,
            status: 'Pending'
        });

    } catch (error) {

        if (transactionStarted && connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Order Rollback Error:', rollbackError);
            }
        }

        console.error('Create Order Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Failed to create order'
        });

    } finally { if (connection) { connection.release(); } }
}

// ==========================================
// Update Order Status (Admin)
// ==========================================
async function updateOrder(req, res) {
    const orderId = parsePositiveId(req.params.id);
    const rawStatus = req.body?.status;

    // ตรวจสอบ Order ID
    if (!orderId) {
        return res.status(400).json({
            message: 'Invalid order ID'
        });
    }

    // ตรวจสอบ Status
    if (
        typeof rawStatus !== 'string' ||
        !rawStatus.trim() ||
        rawStatus.trim().length > 100
    ) {
        return res.status(400).json({
            message: 'Please provide a valid status'
        });
    }

    const newStatus = rawStatus.trim();

    // สถานะที่อนุญาต
    const allowedStatuses = [
        'Processing',
        'Completed'
    ];

    if (!allowedStatuses.includes(newStatus)) {
        return res.status(400).json({
            message: 'Invalid order status'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Lock Order
        const [orders] = await connection.query(
            `SELECT
                order_id,
                status
             FROM orders
             WHERE order_id = ?
             FOR UPDATE`,
            [orderId]
        );

        if (orders.length === 0) {
            const error = new Error('Order not found');
            error.statusCode = 404;
            throw error;
        }

        const currentStatus = orders[0].status;

        // 2. Prevent Updating Cancelled Order
        if (currentStatus === 'Cancelled') {
            const error = new Error(
                'Cancelled order cannot be updated'
            );
            error.statusCode = 409;
            throw error;
        }

        // 3. Validate Current Status
        const validCurrentStatuses = [
            'Pending',
            'Processing',
            'Completed'
        ];

        if (!validCurrentStatuses.includes(currentStatus)) {
            const error = new Error(
                'Invalid current order status'
            );
            error.statusCode = 409;
            throw error;
        }

        // 4. Prevent Completed Order From Reverting
        if (
            currentStatus === 'Completed' &&
            newStatus !== 'Completed'
        ) {
            const error = new Error(
                'Completed order cannot be reverted'
            );
            error.statusCode = 409;
            throw error;
        }

        // 5. Prevent Skipping Processing
        if (
            currentStatus === 'Pending' &&
            newStatus === 'Completed'
        ) {
            const error = new Error(
                'Order must be Processing before Completed'
            );
            error.statusCode = 409;
            throw error;
        }

        // 6. Processing and Completed Require Paid Payment
        if (
            newStatus === 'Processing' ||
            newStatus === 'Completed'
        ) {
            const [payments] = await connection.query(
                `SELECT payment_id
                FROM payments
                WHERE order_id = ?
                AND status = 'Paid'
                LIMIT 1
                FOR UPDATE`,
                [orderId]
            );

            if (payments.length === 0) {
                const error = new Error(
                    'Order payment has not been completed'
                );
                error.statusCode = 409;
                throw error;
            }
        }

        // 7. Update Order
        await connection.query(
            `UPDATE orders
             SET
                status = ?,
                completed_at = CASE
                    WHEN ? = 'Completed'
                    THEN COALESCE(completed_at, NOW())
                    ELSE completed_at
                END
             WHERE order_id = ?`,
            [
                newStatus,
                newStatus,
                orderId
            ]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Order updated successfully',
            order_id: orderId,
            status: newStatus
        });

    } catch (error) {
        if (transactionStarted && connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Order Rollback Error:', rollbackError);
            }
        }

        console.error('Update Order Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });

    } finally { if (connection) { connection.release(); } }
}

// ==========================================
// Delete Order (Cancel Order - Admin)
// ==========================================
async function deleteOrder(req, res, requireOwner = false) {
    const order_id = parsePositiveId(req.params.id);

    if (!order_id) {
        return res.status(400).json({
            message: 'Invalid order ID'
        });
    }

    let connection;
    let transactionStarted = false;

    const rejectRequest = (statusCode, message) => {
        const error = new Error(message);
        error.statusCode = statusCode;
        throw error;
    };

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // ----------------------------------
        // 1. Lock Order
        // ----------------------------------
        const [orderRows] = await connection.query(
            `SELECT
                order_id,
                user_id,
                status,
                spent_points,
                coupon_id,
                user_coupon_id
             FROM orders
             WHERE order_id = ?
             FOR UPDATE`,
            [order_id]
        );

        if (orderRows.length === 0) {
            rejectRequest(404, 'Order not found');
        }

        const order = orderRows[0];

        // Customer can only cancel their own order
        if (
            requireOwner &&
            Number(order.user_id) !== Number(req.user?.user_id)
        ) { rejectRequest(404, 'Order not found'); }

        // ----------------------------------
        // 2. Only Pending Orders Can Be Cancelled
        // ----------------------------------
        if (order.status !== 'Pending') {
            rejectRequest(
                409,
                'Only pending orders can be cancelled'
            );
        }

        // ----------------------------------
        // 3. Lock and Check Payments
        // ----------------------------------
        const [paymentRows] = await connection.query(
            `SELECT
                payment_id,
                status
             FROM payments
             WHERE order_id = ?
             FOR UPDATE`,
            [order_id]
        );

        const hasPaidPayment = paymentRows.some(
            payment => payment.status === 'Paid'
        );

        if (hasPaidPayment) {
            rejectRequest(
                409,
                'Cannot cancel an order with paid payment'
            );
        }

        // ----------------------------------
        // 4. Lock User
        // ----------------------------------
        const userId = Number(order.user_id);

        const [userRows] = await connection.query(
            `SELECT user_id
             FROM users
             WHERE user_id = ?
             FOR UPDATE`,
            [userId]
        );

        if (userRows.length === 0) {
            rejectRequest(404, 'User not found');
        }

        // ----------------------------------
        // 5. Validate Spent Points
        // ----------------------------------
        const spentPoints = Number(order.spent_points);

        if (
            !Number.isSafeInteger(spentPoints) ||
            spentPoints < 0
        ) {
            rejectRequest(409, 'Invalid spent points');
        }

        let pointsRefunded = 0;

        // ----------------------------------
        // 6. Refund Points
        // ----------------------------------
        if (spentPoints > 0) {
            const spendEventKey = `ORDER_${order_id}_SPEND`;
            const refundEventKey = `ORDER_${order_id}_REFUND`;

            // Check Original Spend Transaction
            const [spendRows] = await connection.query(
                `SELECT
                    point_transaction_id,
                    user_id,
                    order_id,
                    type,
                    points_delta
                 FROM point_transactions
                 WHERE event_key = ?
                 FOR UPDATE`,
                [spendEventKey]
            );

            if (spendRows.length === 0) {
                rejectRequest(
                    409,
                    'Original point spending transaction not found'
                );
            }

            const spend = spendRows[0];

            if (
                Number(spend.user_id) !== userId ||
                Number(spend.order_id) !== order_id ||
                spend.type !== 'Spend' ||
                Number(spend.points_delta) !== -spentPoints
            ) {
                rejectRequest(
                    409,
                    'Invalid original point spending transaction'
                );
            }

            // Check Existing Refund
            const [refundRows] = await connection.query(
                `SELECT
                    point_transaction_id,
                    user_id,
                    order_id,
                    type,
                    points_delta
                 FROM point_transactions
                 WHERE event_key = ?
                 FOR UPDATE`,
                [refundEventKey]
            );

            if (refundRows.length === 0) {

                // Insert Refund Transaction
                await connection.query(
                    `INSERT INTO point_transactions (
                        user_id,
                        order_id,
                        event_key,
                        type,
                        points_delta
                    )
                    VALUES (?, ?, ?, ?, ?)`,
                    [
                        userId,
                        order_id,
                        refundEventKey,
                        'Earn',
                        spentPoints
                    ]
                );

                pointsRefunded = spentPoints;

            } else {
                // Validate Existing Refund
                const refund = refundRows[0];
                if (
                    Number(refund.user_id) !== userId ||
                    Number(refund.order_id) !== order_id ||
                    refund.type !== 'Earn' ||
                    Number(refund.points_delta) !== spentPoints
                ) {
                    rejectRequest(
                        409,
                        'Invalid existing point refund transaction'
                    );
                }
            }
        }

        // ----------------------------------
        // 7. Validate Coupon Information
        // ----------------------------------
        let couponRefunded = false;
        const hasCouponId = order.coupon_id !== null;
        const hasUserCouponId = order.user_coupon_id !== null;

        if (hasCouponId !== hasUserCouponId) {
            rejectRequest(
                409,
                'Cannot restore coupon because coupon information is incomplete'
            );
        }

        // ----------------------------------
        // 8. Refund Coupon
        // ----------------------------------
        if (hasCouponId && hasUserCouponId) {

            // Check and Lock User Coupon
            const [userCouponRows] = await connection.query(
                `SELECT
                    user_coupon_id,
                    user_id,
                    coupon_id,
                    used_at
                 FROM user_coupons
                 WHERE user_coupon_id = ?
                   AND user_id = ?
                   AND coupon_id = ?
                 FOR UPDATE`,
                [
                    order.user_coupon_id,
                    userId,
                    order.coupon_id
                ]
            );

            if (userCouponRows.length === 0) {
                rejectRequest(
                    409,
                    'User coupon assignment not found'
                );
            }

            const userCoupon = userCouponRows[0];

            if (userCoupon.used_at === null) {
                rejectRequest(
                    409,
                    'Coupon has not been marked as used'
                );
            }

            // Restore User Coupon
            const [restoreResult] = await connection.query(
                `UPDATE user_coupons
                 SET used_at = NULL
                 WHERE user_coupon_id = ?
                   AND used_at IS NOT NULL`,
                [order.user_coupon_id]
            );

            if (restoreResult.affectedRows !== 1) {
                rejectRequest(
                    409,
                    'Failed to restore user coupon'
                );
            }

            // Decrease Coupon Usage Count
            const [countResult] = await connection.query(
                `UPDATE coupons
                 SET use_count = use_count - 1
                 WHERE coupon_id = ?
                   AND use_count > 0`,
                [order.coupon_id]
            );

            if (countResult.affectedRows !== 1) {
                rejectRequest(
                    409,
                    'Failed to restore coupon usage count'
                );
            }
            couponRefunded = true;
        }

        // ----------------------------------
        // 9. Cancel Order
        // ----------------------------------
        const [updateResult] = await connection.query(
            `UPDATE orders
             SET status = 'Cancelled'
             WHERE order_id = ?
               AND status = 'Pending'`,
            [order_id]
        );

        if (updateResult.affectedRows !== 1) {
            rejectRequest(
                409,
                'Order cancellation failed'
            );
        }

        // ----------------------------------
        // 10. Cancel Pending Payments
        // ----------------------------------
        await connection.query(
            `UPDATE payments
             SET status = 'Cancelled'
             WHERE order_id = ?
               AND status = 'Pending'`,
            [order_id]
        );

        // ----------------------------------
        // 11. Commit Transaction
        // ----------------------------------
        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Order cancelled successfully',
            order_id: order_id,
            status: 'Cancelled',
            points_refunded: pointsRefunded,
            coupon_refunded: couponRefunded
        });

    } catch (error) {
        if (transactionStarted && connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Order Rollback Error:', rollbackError);
            }
        }

        console.error('Delete Order Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });

    } finally { if (connection) { connection.release(); } }
}

// ==========================================
// Cancel My Order (Customer)
// ==========================================
async function cancelMyOrder(req, res) {
    return deleteOrder(req, res, true);
}

// ==========================================
// Export Controllers
// ==========================================
module.exports = {
    getAllOrders,
    getOrderById,
    getMyOrders,
    createOrder,
    updateOrder,
    deleteOrder,
    cancelMyOrder
};