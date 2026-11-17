
const db = require('../db_config');

function parsePositiveId(value) {
    const id = Number(value);

    return Number.isInteger(id) && id > 0
        ? id
        : null;
}

// GET /api/admin/users/all
async function getAllUsers(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                user_id,
                username,
                email,
                display_name,
                role,
                is_active,
                created_at
             FROM users
             WHERE role = 'user'
             ORDER BY created_at DESC, user_id DESC`
        );

        return res.status(200).json({
            users: rows
        });
    } catch (error) {
        console.error('Get All Users Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// PATCH /api/admin/users/:id/status
async function updateUserStatus(req, res) {
    const userId = parsePositiveId(req.params.id);
    const isActive = Number(req.body.is_active);

    if (!userId || ![0, 1].includes(isActive)) {
        return res.status(400).json({
            message: 'Invalid user ID or account status'
        });
    }

    // Prevent changing the currently logged-in account
    if (Number(req.user.user_id) === userId) {
        return res.status(403).json({
            message: 'Cannot change your own account status'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // Lock the target account
        const [users] = await connection.query(
            `SELECT
                user_id,
                role,
                is_active
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

        const user = users[0];

        // Only normal member accounts can be managed here
        if (user.role !== 'user') {
            const error = new Error(
                'Cannot change administrator account status'
            );
            error.statusCode = 403;
            throw error;
        }

        // Update only when the status actually changes
        if (Number(user.is_active) !== isActive) {
            await connection.query(
                `UPDATE users
                 SET is_active = ?
                 WHERE user_id = ?
                   AND role = 'user'`,
                [isActive, userId]
            );
        }

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'User status updated successfully',
            user_id: userId,
            is_active: isActive
        });

    } catch (error) {
        if (transactionStarted && connection) {
            await connection.rollback();
            transactionStarted = false;
        }

        console.error('Update User Status Error:', error);

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


// GET /api/admin/users/:id/details
async function getUserDetails(req, res) {
    const userId = parsePositiveId(req.params.id);

    if (!userId) {
        return res.status(400).json({
            message: 'Invalid user ID'
        });
    }

    let connection;

    try {
        connection = await db.promise().getConnection();

        // 1. Member information
        const [userRows] = await connection.query(
            `SELECT
                user_id,
                username,
                email,
                display_name,
                role,
                is_active,
                created_at
             FROM users
             WHERE user_id = ?
               AND role = 'user'
             LIMIT 1`,
            [userId]
        );

        if (userRows.length === 0) {
            return res.status(404).json({
                message: 'Member not found'
            });
        }

        // 2. Orders
        const [orders] = await connection.query(
            `SELECT
                order_id,
                game_name_snapshot,
                package_name_snapshot,
                player_uid,
                server_code,
                original_price,
                discount_amount,
                total_amount,
                status,
                created_at,
                completed_at,
                coupon_code_snapshot,
                spent_points,
                coupon_discount,
                fee_amount
             FROM orders
             WHERE user_id = ?
             ORDER BY created_at DESC`,
            [userId]
        );

        // 3. Payments
        const [payments] = await connection.query(
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

        // 4. Point transactions
        const [pointTransactions] = await connection.query(
            `SELECT
                point_transaction_id,
                order_id,
                event_key,
                type,
                points_delta,
                created_at
             FROM point_transactions
             WHERE user_id = ?
             ORDER BY created_at DESC`,
            [userId]
        );

        // 5. Receipts
        const [receipts] = await connection.query(
            `SELECT
                r.receipt_id,
                r.order_id,
                r.receipt_number,
                r.issued_at,
                o.game_name_snapshot,
                o.package_name_snapshot
             FROM receipts r
             INNER JOIN orders o
                ON r.order_id = o.order_id
             WHERE o.user_id = ?
             ORDER BY r.issued_at DESC`,
            [userId]
        );

        // 6. Coupons assigned to this member
        const [userCoupons] = await connection.query(
            `SELECT
                uc.user_coupon_id,
                uc.coupon_id,
                uc.used_at,
                c.code,
                c.discount_type,
                c.discount_value,
                c.min_order_amount,
                c.max_discount_amount,
                c.start_date,
                c.end_date,
                c.is_active AS coupon_is_active
             FROM user_coupons uc
             INNER JOIN coupons c
                ON uc.coupon_id = c.coupon_id
             WHERE uc.user_id = ?
             ORDER BY uc.user_coupon_id DESC`,
            [userId]
        );

        const pointBalance = pointTransactions.reduce(
            (total, item) => total + Number(item.points_delta),
            0
        );

        const paidAmount = payments
            .filter(item => item.status === 'Paid')
            .reduce(
                (total, item) => total + Number(item.amount),
                0
            );

        return res.status(200).json({
            user: userRows[0],

            summary: {
                order_count: orders.length,
                payment_count: payments.length,
                paid_amount: Number(paidAmount.toFixed(2)),
                point_balance: pointBalance,
                receipt_count: receipts.length,
                coupon_count: userCoupons.length
            },

            orders,
            payments,
            point_transactions: pointTransactions,
            receipts,
            user_coupons: userCoupons
        });

    } catch (error) {
        console.error('Get User Details Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    } finally {
        if (connection) {
            connection.release();
        }
    }
}


module.exports = {
    getAllUsers,
    updateUserStatus,
    getUserDetails
};
