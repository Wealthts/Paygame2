const db = require('../db_config');

// ตรวจสอบ ID
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


// ==========================================
// Create Receipt (Admin)
// ==========================================
async function createReceipt(req, res) {
    const orderId = parsePositiveId(
        req.body?.order_id
    );

    if (!orderId) {
        return res.status(400).json({
            message: 'Invalid order ID'
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
            `SELECT order_id
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

        // 2. Check Paid Payment
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
                'Order has not been paid'
            );

            error.statusCode = 409;
            throw error;
        }

        // 3. Check Existing Receipt
        const [existingReceipts] = await connection.query(
            `SELECT
                receipt_id,
                order_id,
                receipt_number,
                issued_at
             FROM receipts
             WHERE order_id = ?
             FOR UPDATE`,
            [orderId]
        );

        // ถ้ามี Receipt แล้ว ให้ส่งรายการเดิมกลับไป
        if (existingReceipts.length > 0) {

            await connection.commit();
            transactionStarted = false;

            return res.status(200).json({
                message: 'Receipt already exists',
                receipt: existingReceipts[0]
            });
        }

        // 4. Generate Receipt Number
        const receiptNumber = `RCP_${orderId}`;

        // 5. Insert Receipt
        const [result] = await connection.query(
            `INSERT INTO receipts (
                order_id,
                receipt_number
            )
            VALUES (?, ?)`,
            [
                orderId,
                receiptNumber
            ]
        );

        // อ่านข้อมูล Receipt ที่สร้าง
        const [receiptRows] = await connection.query(
            `SELECT
                receipt_id,
                order_id,
                receipt_number,
                issued_at
             FROM receipts
             WHERE receipt_id = ?`,
            [result.insertId]
        );

        if (receiptRows.length === 0) {
            throw new Error('Failed to retrieve created receipt');
        }

        // 6. Commit
        await connection.commit();
        transactionStarted = false;

        return res.status(201).json({
            message: 'Receipt created successfully',
            receipt: receiptRows[0]
        });

    } catch (error) {
        if (transactionStarted && connection) {
            try {
                await connection.rollback();
            } catch (rollbackError) {
                console.error('Receipt Rollback Error:', rollbackError);
            }
        }

        console.error('Create Receipt Error:', error);

        // กรณี Unique Index ป้องกันข้อมูลซ้ำ
        // ตรวจสอบอีกครั้งว่ามี Receipt เดิมหรือไม่
        if (error.code === 'ER_DUP_ENTRY') {
            try {
                const [existing] = await db.promise().query(
                    `SELECT
                        receipt_id,
                        order_id,
                        receipt_number,
                        issued_at
                     FROM receipts
                     WHERE order_id = ?`,
                    [orderId]
                );

                if (existing.length > 0) {
                    return res.status(200).json({
                        message: 'Receipt already exists',
                        receipt: existing[0]
                    });
                }

            } catch (queryError) {
                console.error('Find Existing Receipt Error:', queryError);
            }

            return res.status(409).json({
                message: 'Receipt number already exists'
            });
        }

        return res.status(error.statusCode || 500).json({
            message: error.statusCode
                ? error.message
                : 'Internal server error'
        });

    } finally { if (connection) { connection.release(); } }
}

// ==========================================
// Get All Receipts (Admin)
// ==========================================
async function getAllReceipts(req, res) {
    try {
        const [rows] = await db.promise().query(
            `SELECT
                r.receipt_id,
                r.order_id,
                r.receipt_number,
                r.issued_at,
                o.user_id,
                o.game_name_snapshot,
                o.package_name_snapshot,
                o.total_amount,
                u.username,
                u.display_name
             FROM receipts r
             INNER JOIN orders o
                ON r.order_id = o.order_id
             INNER JOIN users u
                ON o.user_id = u.user_id
             ORDER BY r.issued_at DESC`
        );

        return res.status(200).json({
            receipts: rows
        });

    } catch (error) {
        console.error('Get All Receipts Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Get Receipt By ID (User/Admin)
// ==========================================
async function getReceiptById(req, res) {
    try {
        const receiptId = parsePositiveId(req.params.id);

        if (!receiptId) {
            return res.status(400).json({
                message: 'Invalid receipt ID'
            });
        }

        const [rows] = await db.promise().query(
            `SELECT
                r.receipt_id,
                r.order_id,
                r.receipt_number,
                r.issued_at,
                o.user_id,
                o.game_name_snapshot,
                o.package_name_snapshot,
                o.total_amount,
                o.player_uid,
                o.server_code,
                u.username,
                u.display_name
             FROM receipts r
             INNER JOIN orders o
                ON r.order_id = o.order_id
             INNER JOIN users u
                ON o.user_id = u.user_id
             WHERE r.receipt_id = ?`,
            [receiptId]
        );

        if (rows.length === 0) {
            return res.status(404).json({
                message: 'Receipt not found'
            });
        }

        const receipt = rows[0];

        // User ดูได้เฉพาะ Receipt ของตัวเอง
        if (
            req.user.role !== 'admin' &&
            Number(receipt.user_id) !== Number(req.user.user_id)
        ) {
            return res.status(404).json({
                message: 'Receipt not found'
            });
        } return res.status(200).json(receipt);

    } catch (error) {
        console.error('Get Receipt By ID Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Get My Receipts (User)
// ==========================================
async function getMyReceipts(req, res) {
    try {
        const userId = parsePositiveId(req.user?.user_id);

        if (!userId) {
            return res.status(401).json({
                message: 'Invalid user'
            });
        }

        const [rows] = await db.promise().query(
            `SELECT
                r.receipt_id,
                r.order_id,
                r.receipt_number,
                r.issued_at,
                o.game_name_snapshot,
                o.package_name_snapshot,
                o.total_amount
             FROM receipts r
             INNER JOIN orders o
                ON r.order_id = o.order_id
             WHERE o.user_id = ?
             ORDER BY r.issued_at DESC`,
            [userId]
        );

        return res.status(200).json({
            receipts: rows
        });

    } catch (error) {
        console.error('Get My Receipts Error:', error);
        return res.status(500).json({
            message: 'Internal server error'
        });
    }
}

// ==========================================
// Export Controllers
// ==========================================
module.exports = {
    createReceipt,
    getAllReceipts,
    getReceiptById,
    getMyReceipts
};
