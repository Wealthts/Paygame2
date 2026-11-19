const path = require('path');

// 1. Load Environment Variables
require('dotenv').config({
    path: path.resolve(__dirname, '.env')
});

// 2. Validate Environment Variables
const requiredEnv = ['DB_HOST', 'DB_USER', 'DB_NAME', 'JWT_KEY'];

for (const key of requiredEnv) {
    if (!process.env[key]) {
        throw new Error(`${key} is not configured`);
    }
}

// 3. Import Packages
const express = require('express');
const cors = require('cors');
const db = require('./db_config');

// 4. Create Express Application
const app = express();

// 5. Middleware
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));

// 6. Static Uploads
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// 7. Import Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/user');
const userAdminRoutes = require('./routes/user_admin');
const gameRoutes = require('./routes/game');
const gameAdminRoutes = require('./routes/game_admin');
const packageRoutes = require('./routes/package');
const packageAdminRoutes = require('./routes/package_admin');
const orderRoutes = require('./routes/order');
const paymentRoutes = require('./routes/payment');
const pointRoutes = require('./routes/point');
const receiptRoutes = require('./routes/receipt');
const couponRoutes = require('./routes/coupon');
const couponAdminRoutes = require('./routes/coupon_admin');
const userCouponRoutes = require('./routes/user_coupon');
const userCouponAdminRoutes = require('./routes/user_coupon_admin');
// Mounted at /api/admin/reports; report routes apply both auth and admin guards.
const reportRoutes = require('./routes/report');

// 8. Register Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin/users', userAdminRoutes);
app.use('/api/games', gameRoutes);
app.use('/api/admin/games', gameAdminRoutes);
app.use('/api/packages', packageRoutes);
app.use('/api/admin/packages', packageAdminRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/points', pointRoutes);
app.use('/api/receipts', receiptRoutes);
app.use('/api/coupons', couponRoutes);
app.use('/api/admin/coupons', couponAdminRoutes);
app.use('/api/user-coupons', userCouponRoutes);
app.use('/api/admin/user-coupons', userCouponAdminRoutes);
app.use('/api/admin/reports', reportRoutes);


// 9. Root Route
app.get('/', (req, res) => {
    return res.status(200).json({
        message: 'Welcome to the PayGame API'
    });
});

// 10. Route Not Found
app.use((req, res) => {
    return res.status(404).json({
        message: 'Route not found'
    });
});

// 11. Global Error Handler
app.use((error, req, res, next) => {
    console.error('Global Error:', error);
    if (res.headersSent) {
        return next(error);
    }
    return res.status(error.statusCode || 500).json({
        message: error.statusCode
            ? error.message
            : 'Internal server error'
    });
});

// 12. Start Server After Database Ready
const PORT = Number(process.env.PORT) || 3000;
async function startServer() {
    try {
        // Test Database Connection
        await db.promise().query('SELECT 1');
        console.log('Database connected successfully');

        // Start Express Server
        const server = app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });

        // 13. Graceful Shutdown
        let shuttingDown = false;
        async function shutdown(signal) {
            if (shuttingDown) {
                return;
            }

            shuttingDown = true;
            console.log(`${signal} received. Closing server...`);
            server.close(async (error) => {

                if (error) {
                    console.error('Server close error:', error);
                }

                try {
                    await db.promise().end();
                    console.log('Database pool closed');

                } catch (dbError) {
                    console.error('Database close error:', dbError);
                    process.exitCode = 1;
                }

                console.log('Server shutdown complete');
                if (error) {
                    process.exitCode = 1;
                }
            });
        }

        process.on('SIGINT', () => shutdown('SIGINT'));
        process.on('SIGTERM', () => shutdown('SIGTERM'));

    } catch (error) {
        console.error('Server startup failed:', {
            message: error.message,
            code: error.code,
            errno: error.errno,
            syscall: error.syscall,
            address: error.address,
            port: error.port
        });
        try {
            await db.promise().end();
        } catch (dbError) {
            console.error('Database shutdown error:', dbError);
        }
        process.exitCode = 1;
    }
}

// 14. Run Application
startServer();
