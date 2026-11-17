const db = require('../db_config');

// ==========================================
// Get My Points (Customer)
// ==========================================
async function getMyPoints(req, res) {
    try {
        const userId = req.user.user_id;

        const [rows] = await db.promise().query(
            `SELECT
                COUNT(*) AS transaction_count,
                COALESCE(SUM(points_delta), 0) AS total_points
             FROM point_transactions
             WHERE user_id = ?`,
            [userId]
        );

        const totalPoints = Number(rows[0].total_points);
        const transactionCount = Number(rows[0].transaction_count);

        // ตรวจสอบความถูกต้องของยอดแต้ม
        if (
            !Number.isSafeInteger(totalPoints) ||
            totalPoints < 0
        ) {
            console.error(
                'Invalid point balance detected:',
                {
                    userId,
                    totalPoints
                }
            );

            return res.status(409).json({
                message: 'Invalid point balance. Please contact administrator.'
            });
        }

        return res.status(200).json({
            total_points: totalPoints,
            transaction_count: transactionCount
        });

    } catch (error) {
        console.error('Get My Points Error:', error);

        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// View the point transaction history of the logged-in user
async function getMyPointHistory(req, res) {
    try {
        const userId = req.user.user_id;

        const [rows] = await db.promise().query(
            `SELECT
                point_transaction_id,
                order_id,
                event_key,
                type,
                points_delta,
                created_at
             FROM point_transactions
             WHERE user_id = ?
             ORDER BY created_at DESC,
             point_transaction_id DESC`,
            [userId]
        );

        return res.status(200).json({
            history: rows
        });

    } catch (error) {
        console.error("Get Point History Error:", error);

        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// View all point transactions (Admin)
async function getAllPointTransactions(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                pt.*,
                u.username,
                u.display_name
             FROM point_transactions pt
             INNER JOIN users u
                ON pt.user_id = u.user_id
             ORDER BY pt.created_at DESC`
        );

        return res.status(200).json({
            transactions: rows
        });

    } catch (error) {
        console.error('Get All Points Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// View point transaction by ID (Admin)
async function getPointTransactionById(req, res) {
    try {
        const pointId = Number(req.params.id);

        if (!Number.isInteger(pointId) || pointId <= 0) {
            return res.status(400).json({
                message: 'Invalid point transaction ID'
            });
        }

        const [rows] = await db.promise().query(
            `SELECT
                pt.*,
                u.username,
                u.display_name
             FROM point_transactions pt
             INNER JOIN users u
                ON pt.user_id = u.user_id
             WHERE pt.point_transaction_id = ?`,
            [pointId]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                message: 'Point transaction not found'
            });
        }

        return res.status(200).json(rows[0]);

    } catch (error) {
        console.error('Get Point By ID Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// Create point transaction (Admin)
async function createPointTransaction(req, res) {
    const { user_id, event_key, type, points_delta } = req.body || {};
    const userId = Number(user_id);
    const pointsDelta = Number(points_delta);
    const eventKey = typeof event_key === 'string'
        ? event_key.trim()
        : '';

    if (eventKey.toLocaleLowerCase().startsWith('ORDER_')) {
        return res.status(400).json({
            message: 'ORDER_ event keys are reserved for system transactions'
        });
    }

    if (
        !Number.isInteger(userId) || userId <= 0 ||
        !eventKey || eventKey.length > 100 ||
        !['Earn', 'Spend'].includes(type) ||
        !Number.isInteger(pointsDelta) ||
        pointsDelta === 0 ||
        (type === 'Earn' && pointsDelta < 0) ||
        (type === 'Spend' && pointsDelta > 0)
    ) {
        return res.status(400).json({
            message: 'Invalid point transaction data'
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

        // 2. Read current balance
        const [balanceRows] = await connection.query(
            `SELECT COALESCE(SUM(points_delta), 0)
             AS total_points
             FROM point_transactions
             WHERE user_id = ?`,
            [userId]
        );

        const balance = Number(balanceRows[0].total_points);

        if (balance + pointsDelta < 0) {
            const error = new Error('Insufficient points');
            error.statusCode = 400;
            throw error;
        }

        // 3. Insert manual point transaction
        const [result] = await connection.query(
            `INSERT INTO point_transactions (
                user_id,
                order_id,
                event_key,
                type,
                points_delta
            )
            VALUES (?, NULL, ?, ?, ?)`,
            [userId, eventKey, type, pointsDelta]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'Point transaction created successfully',
            point_transaction_id: result.insertId
        });

    } catch (error) {

        if (transactionStarted && connection) await connection.rollback();

        console.error('Create Point Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Event key already exists'
            });
        }

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
}


// Update manual point transaction (Admin)
async function updatePointTransaction(req, res) {
    const pointId = Number(req.params.id);
    const { event_key, type, points_delta } = req.body || {};
    const eventKey = typeof event_key === 'string'
        ? event_key.trim()
        : '';

    if (eventKey.toUpperCase().startsWith('ORDER_')) {
        return res.status(400).json({
            message: 'ORDER_ event keys are reserved for system transactions'
        });
    }

    const pointsDelta = Number(points_delta);

    if (
        !Number.isInteger(pointId) ||
        pointId <= 0 || !eventKey ||
        eventKey.length > 100 ||
        !['Earn', 'Spend'].includes(type) ||
        !Number.isInteger(pointsDelta) ||
        pointsDelta === 0 ||
        (type === 'Earn' && pointsDelta < 0) ||
        (type === 'Spend' && pointsDelta > 0)
    ) {
        return res.status(400).json({
            message: 'Invalid point transaction data'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Read owner ID first
        const [initialRows] = await connection.query(
            `SELECT user_id
             FROM point_transactions
             WHERE point_transaction_id = ?`,
            [pointId]
        );

        if (initialRows.length === 0) {
            const error = new Error('Point transaction not found');
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

        // 3. Lock transaction row
        const [rows] = await connection.query(
            `SELECT *
             FROM point_transactions
             WHERE point_transaction_id = ?
             FOR UPDATE`,
            [pointId]
        );

        if (rows.length === 0) {
            const error = new Error('Point transaction not found');
            error.statusCode = 404;
            throw error;
        }

        const oldTransaction = rows[0];

        if (
            Number(oldTransaction.user_id) !== Number(userId) ||
            oldTransaction.order_id !== null
        ) {
            const error = new Error('Cannot edit order point transactions');
            error.statusCode = 403;
            throw error;
        }

        // 4. Check duplicate event key
        const [duplicates] = await connection.query(
            `SELECT point_transaction_id
             FROM point_transactions
             WHERE event_key = ?
             AND point_transaction_id <> ?
             LIMIT 1`,
            [eventKey, pointId]
        );

        if (duplicates.length > 0) {
            const error = new Error('Event key already exists');
            error.statusCode = 409;
            throw error;
        }

        // 5. Calculate balance after update
        const [balanceRows] = await connection.query(
            `SELECT COALESCE(SUM(points_delta), 0)
             AS total_points
             FROM point_transactions
             WHERE user_id = ?`,
            [userId]
        );

        const currentBalance = Number(balanceRows[0].total_points);

        const newBalance =
            currentBalance -
            Number(oldTransaction.points_delta) +
            pointsDelta;

        if (newBalance < 0) {
            const error = new Error('Insufficient points after update');
            error.statusCode = 400;
            throw error;
        }

        // 6. Update transaction
        await connection.query(
            `UPDATE point_transactions
             SET event_key = ?,
                 type = ?,
                 points_delta = ?
             WHERE point_transaction_id = ?`,
            [eventKey, type, pointsDelta, pointId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Point transaction updated successfully'
        });

    } catch (error) {

        if (transactionStarted && connection) await connection.rollback();

        console.error('Update Point Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: 'Event key already exists'
            });
        }

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
}


// Delete manual point transaction (Admin)
async function deletePointTransaction(req, res) {
    const pointId = Number(req.params.id);

    if (!Number.isInteger(pointId) || pointId <= 0) {
        return res.status(400).json({
            message: 'Invalid point transaction ID'
        });
    }

    let connection;
    let transactionStarted = false;

    try {
        connection = await db.promise().getConnection();

        await connection.beginTransaction();
        transactionStarted = true;

        // 1. Read owner ID
        const [initialRows] = await connection.query(
            `SELECT user_id
             FROM point_transactions
             WHERE point_transaction_id = ?`,
            [pointId]
        );

        if (initialRows.length === 0) {
            const error = new Error('Point transaction not found');
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

        // 3. Lock point transaction
        const [rows] = await connection.query(
            `SELECT *
             FROM point_transactions
             WHERE point_transaction_id = ?
             FOR UPDATE`,
            [pointId]
        );

        if (rows.length === 0) {
            const error = new Error('Point transaction not found');
            error.statusCode = 404;
            throw error;
        }

        const transaction = rows[0];

        if (
            Number(transaction.user_id) !== Number(userId) ||
            transaction.order_id !== null
        ) {
            const error = new Error('Cannot delete order point transactions');
            error.statusCode = 403;
            throw error;
        }

        // 4. Check current balance
        const [balanceRows] = await connection.query(
            `SELECT COALESCE(SUM(points_delta), 0)
             AS total_points
             FROM point_transactions
             WHERE user_id = ?`,
            [userId]
        );

        const currentBalance = Number(balanceRows[0].total_points);

        const newBalance =
            currentBalance -
            Number(transaction.points_delta);

        if (newBalance < 0) {
            const error = new Error('Cannot delete because user balance would be negative');
            error.statusCode = 400;
            throw error;
        }

        // 5. Delete transaction
        await connection.query(
            `DELETE FROM point_transactions
             WHERE point_transaction_id = ?`,
            [pointId]
        );

        await connection.commit();
        transactionStarted = false;

        return res.status(200).json({
            message: 'Point transaction deleted successfully'
        });

    } catch (error) {

        if (transactionStarted && connection) {
            await connection.rollback();
        }

        console.error('Delete Point Error:', error);

        return res.status(error.statusCode || 500).json({
            message: error.statusCode ? error.message : 'Internal server error'
        });

    } finally { if (connection) connection.release(); }
}

module.exports = {
    getMyPoints,
    getMyPointHistory,
    getAllPointTransactions,
    getPointTransactionById,
    createPointTransaction,
    updatePointTransaction,
    deletePointTransaction
};