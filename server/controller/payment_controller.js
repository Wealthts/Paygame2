const db = require('../db_config');

// Get all payments
async function getAllPayments(req, res) {
    try {
        const [payments] = await db.promise().query(
            `SELECT
                payments.*,
                orders.user_id,
                orders.game_name_snapshot,
                orders.package_name_snapshot,
                users.username,
                users.display_name
             FROM payments
             INNER JOIN orders
             ON payments.order_id = orders.order_id
             INNER JOIN users
             ON orders.user_id = users.user_id
             ORDER BY payments.created_at DESC`
        );

        return res.status(200).json({
            payments: payments
        });

    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Get payment by ID
async function getPaymentById(req, res) {
    try {
        const paymentId = Number(req.params.id);

        // Check payment ID
        if (!Number.isInteger(paymentId) || paymentId <= 0) {
            return res.status(400).json({
                message: "Invalid payment ID"
            });
        }

        // Get payment details
        const [payments] = await db.promise().query(
            `SELECT
                payments.*,
                orders.user_id,
                orders.game_name_snapshot,
                orders.package_name_snapshot,
                users.username,
                users.display_name
             FROM payments
             INNER JOIN orders
             ON payments.order_id = orders.order_id
             INNER JOIN users
             ON orders.user_id = users.user_id
             WHERE payments.payment_id = ?`,
            [paymentId]
        );

        if (payments.length === 0) {
            return res.status(404).json({
                message: "Payment not found"
            });
        }

        return res.status(200).json({
            payment: payments[0]
        });

    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Get payments belonging to logged-in user
async function getMyPayments(req, res) {
    try {
        const userId = req.user.user_id;

        const [payments] = await db.promise().query(
            `SELECT
                p.payment_id,
                p.order_id,
                p.transaction_ref,
                p.method,
                p.amount,
                p.status,
                p.created_at,
                p.paid_at,
                o.game_name_snapshot,
                o.package_name_snapshot
             FROM payments p
             INNER JOIN orders o
                ON p.order_id = o.order_id
             WHERE o.user_id = ?
             ORDER BY p.created_at DESC`,
            [userId]
        );

        return res.status(200).json({
            payments: payments
        });

    } catch (error) {
        console.error('Get My Payments Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Create payment
async function createPayment(req, res) {
    const { order_id, transaction_ref, method } = req.body || {};
    const orderId = Number(order_id);

    if (
        !Number.isInteger(orderId) ||
        orderId <= 0 ||
        typeof transaction_ref !== 'string' ||
        !transaction_ref.trim() ||
        transaction_ref.trim().length > 100 ||
        typeof method !== 'string' ||
        !method.trim() ||
        method.trim().length > 100
    ) {
        return res.status(400).json({
            message: "Please provide valid payment information"
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Lock order
        const [orders] = await connection.query(
            `SELECT order_id, total_amount, status
             FROM orders
             WHERE order_id = ?
             AND user_id = ?
             FOR UPDATE`,
            [orderId, req.user.user_id]
        );

        if (orders.length === 0) {
            const error = new Error('Order not found');
            error.statusCode = 404;
            throw error;
        }

        const order = orders[0];

        // 2. Check order status
        if (order.status !== 'Pending') {
            const error = new Error("Only pending orders can be paid");
            error.statusCode = 409;
            throw error;
        }

        // 3. Check existing payment
        const [existingPayments] = await connection.query(
            `SELECT payment_id
             FROM payments
             WHERE order_id = ?
             LIMIT 1`,
            [orderId]
        );

        if (existingPayments.length > 0) {
            const error = new Error("Payment already exists for this order");
            error.statusCode = 409;
            throw error;
        }

        // 4. Insert payment
        const [result] = await connection.query(
            `INSERT INTO payments (
                order_id,
                transaction_ref,
                method,
                amount,
                status
            )
            VALUES (?, ?, ?, ?, ?)`,
            [
                orderId, transaction_ref.trim(),
                method.trim(), order.total_amount,
                'Pending'
            ]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: "Payment created successfully",
            payment_id: result.insertId,
            order_id: orderId,
            amount: order.total_amount,
            status: "Pending"
        });

    } catch (error) {

        if (transactionStarted && connection) await connection.rollback();

        console.error('Create Payment Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Payment or transaction reference already exists'
            });
        }

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
}


// Update payment status
const updatePayment = async (req, res) => {
    const paymentId = Number(req.params.id);
    const status = req.body ? req.body.status : undefined;

    if (!Number.isInteger(paymentId) || paymentId <= 0) {
        return res.status(400).json({
            message: "Invalid payment ID"
        });
    }

    if (
        typeof status !== 'string' ||
        !['Pending', 'Paid'].includes(status)
    ) {
        return res.status(400).json({
            message: "Invalid payment status"
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Find order ID first (non-locking read)
        const [paymentInfo] = await connection.query(
            `SELECT order_id
             FROM payments
             WHERE payment_id = ?`,
            [paymentId]
        );

        if (paymentInfo.length === 0) {
            const error = new Error('Payment not found');
            error.statusCode = 404;
            throw error;
        }

        const orderId = paymentInfo[0].order_id;

        // 2. Lock order first
        const [orderRows] = await connection.query(
            `SELECT
                o.order_id,
                o.user_id,
                o.status AS order_status,
                pk.reward_points
             FROM orders o
             JOIN packages pk
                ON o.package_id = pk.package_id
             WHERE o.order_id = ?
             FOR UPDATE`,
            [orderId]
        );

        if (orderRows.length === 0) {
            const error = new Error('Order not found');
            error.statusCode = 404;
            throw error;
        }

        const order = orderRows[0];

        // 3. Lock payment after order
        const [paymentRows] = await connection.query(
            `SELECT payment_id, order_id, status
             FROM payments
             WHERE payment_id = ?
             AND order_id = ?
             FOR UPDATE`,
            [paymentId, orderId]
        );

        if (paymentRows.length === 0) {
            const error = new Error('Payment not found');
            error.statusCode = 404;
            throw error;
        }

        const payment = paymentRows[0];

        // ตรวจสอบว่าเป็นการเปลี่ยนเป็น Paid ครั้งแรกหรือไม่
        const isNewlyPaid =
            payment.status !== 'Paid' &&
            status === 'Paid';

        // Prevent cancelled payment from being reactivated
        if (payment.status === 'Cancelled') {
            const error = new Error('Cancelled payment cannot be updated');
            error.statusCode = 409;
            throw error;
        }

        // 4. Prevent payment update for cancelled order
        if (order.order_status === 'Cancelled') {
            const error = new Error('Cannot update payment of a cancelled order');
            error.statusCode = 409;
            throw error;
        }

        // 5. Prevent Paid -> Pending
        if (payment.status === 'Paid' && status !== 'Paid') {
            const error = new Error('Paid payment cannot be changed to Pending');
            error.statusCode = 400;
            throw error;
        }

        // 6. New payment can be Paid only if order is Pending
        if (
            payment.status !== 'Paid' &&
            status === 'Paid' &&
            order.order_status !== 'Pending'
        ) {
            const error = new Error('Order is not available for payment');
            error.statusCode = 409;
            throw error;
        }

        const rewardPoints = Number(order.reward_points);

        if (
            !Number.isInteger(rewardPoints) ||
            rewardPoints < 0
        ) throw new Error('Invalid reward points');

        // 7. Update payment status
        await connection.query(
            `UPDATE payments
             SET
                status = ?,
                paid_at = CASE
                    WHEN ? = 'Paid'
                    THEN COALESCE(paid_at, NOW())
                    ELSE paid_at
                END
             WHERE payment_id = ?`,
            [status, status, paymentId]
        );

        // เมื่อชำระเงินสำเร็จ ให้ปิด order
        if (
            status === 'Paid' &&
            order.order_status === 'Pending'
        ) {
            const [orderUpdate] = await connection.query(
                `UPDATE orders
                SET
                    status = 'Completed',
                    completed_at = COALESCE(completed_at, NOW())
                WHERE order_id = ?
                AND status = 'Pending'`,
                [orderId]
            );

            if (orderUpdate.affectedRows !== 1) {
                const error = new Error(
                    'Failed to complete order'
                );
                error.statusCode = 409;
                throw error;
            }
        }

        // ==========================================
        // 8. Auto Create Receipt
        // ==========================================
        let receipt = null;

        if (status === 'Paid') {
            // ตรวจสอบใบเสร็จเดิมก่อน
            const [existingReceipts] = await connection.query(
                `SELECT
                    receipt_id,
                    order_id,
                    receipt_number,
                    issued_at
                FROM receipts
                WHERE order_id = ?
                LIMIT 1
                FOR UPDATE`,
                [orderId]
            );
            if (existingReceipts.length > 0) {
                // ใช้ใบเสร็จเดิม ไม่สร้างซ้ำ
                receipt = existingReceipts[0];
            } else {
                // สร้างเลขใบเสร็จ
                const receiptNumber = `RCP_${orderId}`;
                // บันทึกใบเสร็จ
                const [receiptResult] = await connection.query(
                    `INSERT INTO receipts (
                        order_id,
                        receipt_number
                    )
                    VALUES (?, ?)`,
                    [orderId, receiptNumber]
                );

                // อ่านใบเสร็จที่สร้าง
                const [receiptRows] = await connection.query(
                    `SELECT
                        receipt_id,
                        order_id,
                        receipt_number,
                        issued_at
                    FROM receipts
                    WHERE receipt_id = ?`,
                    [receiptResult.insertId]
                );

                if (receiptRows.length === 0) {
                    const error = new Error(
                        'Failed to create receipt'
                    );
                    error.statusCode = 500;
                    throw error;
                }
                receipt = receiptRows[0];
            }
        }

        let pointsEarned = 0;

        // 9. Earn points when payment becomes Paid
        if (isNewlyPaid && rewardPoints > 0) {

            // Lock user before inserting point transaction
            const [userRows] = await connection.query(
                `SELECT user_id
                 FROM users
                 WHERE user_id = ?
                 FOR UPDATE`,
                [order.user_id]
            );

            if (userRows.length === 0) {
                const error = new Error('User not found');
                error.statusCode = 404;
                throw error;
            }

            const eventKey = `ORDER_${orderId}`;

            // Check existing event key
            const [existingPoints] = await connection.query(
                `SELECT
                    user_id,
                    order_id,
                    type,
                    points_delta
                 FROM point_transactions
                 WHERE event_key = ?
                 FOR UPDATE`,
                [eventKey]
            );

            if (existingPoints.length === 0) {

                await connection.query(
                    `INSERT INTO point_transactions (
                        user_id,
                        order_id,
                        event_key,
                        type,
                        points_delta
                    )
                    VALUES (?, ?, ?, ?, ?)`,
                    [order.user_id, orderId, eventKey, 'Earn', rewardPoints]
                );
                pointsEarned = rewardPoints;

            } else {
                const oldPoint = existingPoints[0];
                // Validate existing transaction
                if (
                    Number(oldPoint.user_id) !== Number(order.user_id) ||
                    Number(oldPoint.order_id) !== Number(orderId) ||
                    oldPoint.type !== 'Earn' ||
                    Number(oldPoint.points_delta) !== rewardPoints
                ) {
                    const error = new Error('Invalid existing point transaction');
                    error.statusCode = 409;
                    throw error;
                }
                pointsEarned = 0;
            }
        }

        // 10. Commit
        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Payment updated successfully',
            payment_id: paymentId,
            order_id: orderId,
            status: status,
            points_earned: pointsEarned,

            receipt_issued: receipt !== null,
            receipt: receipt
        });

    } catch (error) {
        if (transactionStarted && connection) await connection.rollback();
        console.error('Update Payment Error:', error);
        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });
    } finally { if (connection) connection.release(); }
};


// Delete payment (Cancel payment)
async function deletePayment(req, res) {
    const paymentId = Number(req.params.id);

    if (!Number.isInteger(paymentId) || paymentId <= 0) {
        return res.status(400).json({
            message: 'Invalid payment ID'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Find order ID
        const [paymentInfo] = await connection.query(
            `SELECT order_id
             FROM payments
             WHERE payment_id = ?`,
            [paymentId]
        );

        if (paymentInfo.length === 0) {
            const error = new Error('Payment not found');
            error.statusCode = 404;
            throw error;
        }

        const orderId = paymentInfo[0].order_id;

        // 2. Lock order first
        const [orders] = await connection.query(
            `SELECT order_id, status
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

        // Only pending orders can have their payment cancelled
        if (orders[0].status !== 'Pending') {
            const error = new Error('Only payments of pending orders can be cancelled');
            error.statusCode = 409;
            throw error;
        }

        // 3. Lock payment
        const [payments] = await connection.query(
            `SELECT payment_id, status
             FROM payments
             WHERE payment_id = ?
             AND order_id = ?
             FOR UPDATE`,
            [paymentId, orderId]
        );

        if (payments.length === 0) {
            const error = new Error('Payment not found');
            error.statusCode = 404;
            throw error;
        }

        if (payments[0].status !== 'Pending') {
            const error = new Error('Only pending payments can be cancelled');
            error.statusCode = 409;
            throw error;
        }

        // 4. Cancel payment
        await connection.query(
            `UPDATE payments
             SET status = 'Cancelled'
             WHERE payment_id = ?`,
            [paymentId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Payment cancelled successfully',
            payment_id: paymentId,
            status: 'Cancelled'
        });

    } catch (error) {

        if (transactionStarted && connection) await connection.rollback();

        console.error('Delete Payment Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
}


module.exports = { getAllPayments, getMyPayments, createPayment, getPaymentById, updatePayment, deletePayment };