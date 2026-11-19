const db = require('../db_config');

// Admin report controller: converts SQL aggregates into JSON used by Mobile.
// A request reaches this file only after verifyToken and verifyAdmin in report routes.

// GET /api/admin/reports/summary
// ภาพรวมระบบ
// Summary: order counts, paid revenue, and member count for dashboard cards.
async function getSummary(req, res) {
    try {
        const [[orderRows], [paymentRows], [memberRows]] = await Promise.all([
            db.promise().query(`
                SELECT
                    COUNT(*) AS total_orders,
                    COALESCE(SUM(
                        CASE WHEN status = 'Pending'
                        THEN 1 ELSE 0 END
                    ), 0) AS pending_orders,
                    COALESCE(SUM(
                        CASE WHEN status = 'Completed'
                        THEN 1 ELSE 0 END
                    ), 0) AS completed_orders,
                    COALESCE(SUM(
                        CASE WHEN status = 'Cancelled'
                        THEN 1 ELSE 0 END
                    ), 0) AS cancelled_orders
                FROM orders
            `),

            db.promise().query(`
                SELECT
                    COUNT(*) AS paid_payment_count,
                    COALESCE(SUM(amount), 0) AS total_revenue
                FROM payments
                WHERE status = 'Paid'
                AND paid_at IS NOT NULL
            `),

            db.promise().query(`
                SELECT COUNT(*) AS total_members
                FROM users
                WHERE role = 'user'
            `)
        ]);

        return res.status(200).json({
            summary: {
                total_orders: Number(orderRows[0].total_orders),
                pending_orders: Number(orderRows[0].pending_orders),
                completed_orders: Number(orderRows[0].completed_orders),
                cancelled_orders: Number(orderRows[0].cancelled_orders),

                paid_payment_count: Number(paymentRows[0].paid_payment_count),
                total_revenue: Number(paymentRows[0].total_revenue),
                total_members: Number(memberRows[0].total_members)
            }
        });

    } catch (error) {
        console.error("Get Report Summary Error:", error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// GET /api/admin/reports/monthly-revenue
// รายได้รายเดือนย้อนหลัง 6 เดือน รวมเดือนปัจจุบัน
// Monthly revenue: approved Paid payments for the current and previous five months.
async function getMonthlyRevenue(req, res) {
    try {
        const [rows] = await db.promise().query(`
            SELECT
                DATE_FORMAT(paid_at, '%Y-%m') AS month,
                COALESCE(SUM(amount), 0) AS revenue,
                COUNT(*) AS payment_count
            FROM payments
            WHERE status = 'Paid'
                AND paid_at IS NOT NULL
                AND paid_at >= DATE_SUB(
                    DATE_FORMAT(CURDATE(), '%Y-%m-01'),
                    INTERVAL 5 MONTH
                )
            GROUP BY DATE_FORMAT(paid_at, '%Y-%m')
            ORDER BY month ASC
        `);

        return res.status(200).json({
            monthly_revenue: rows.map(row => ({
                month: row.month,
                revenue: Number(row.revenue),
                payment_count: Number(row.payment_count)
            }))
        });

    } catch (error) {
        console.error("Get Monthly Revenue Error:", error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// GET /api/admin/reports/top-games
// เกมยอดนิยม 5 อันดับ
// Top games: rank five games by order count and completed sales.
async function getTopGames(req, res) {
    try {
        const [rows] = await db.promise().query(`
            SELECT
                game_name_snapshot AS game_name,
                COUNT(*) AS order_count,
                COALESCE(SUM(
                    CASE
                        WHEN status = 'Completed'
                        THEN total_amount
                        ELSE 0
                    END
                ), 0) AS completed_sales
            FROM orders
            GROUP BY game_name_snapshot
            ORDER BY order_count DESC, game_name_snapshot ASC
            LIMIT 5
        `);

        return res.status(200).json({
            top_games: rows.map(row => ({
                game_name: row.game_name,
                order_count: Number(row.order_count),
                completed_sales: Number(row.completed_sales)
            }))
        });

    } catch (error) {
        console.error("Get Top Games Error:", error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// GET /api/admin/reports/order-statuses
// จำนวนคำสั่งซื้อแยกตามสถานะทั้งหมด
// Order statuses: grouped order totals used by filters and progress bars.
async function getOrderStatuses(req, res) {
    try {
        const [rows] = await db.promise().query(`
            SELECT
                status,
                COUNT(*) AS order_count
            FROM orders
            GROUP BY status
            ORDER BY order_count DESC
        `);

        return res.status(200).json({
            order_statuses: rows.map(row => ({
                status: row.status,
                order_count: Number(row.order_count)
            }))
        });

    } catch (error) {
        console.error("Get Order Statuses Error:", error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

module.exports = {
    getSummary,
    getMonthlyRevenue,
    getTopGames,
    getOrderStatuses
};