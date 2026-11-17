
const jwt = require('jsonwebtoken');
const db = require('../db_config');

const JWT_KEY = process.env.JWT_KEY;


// Verify JWT Token
async function verifyToken(req, res, next) {

    const authHeader = req.headers.authorization;

    // 1. Check Authorization Header
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({
            message: "Access token required"
        });
    }

    const token = authHeader.substring(7).trim();

    if (!token) {
        return res.status(401).json({
            message: "Invalid authorization format"
        });
    }

    let payload;

    // 2. Verify JWT
    try {
        payload = jwt.verify(token, JWT_KEY);
        const tokenUserId = Number(payload.user_id);

        if (
            !Number.isSafeInteger(tokenUserId) ||
            tokenUserId <= 0
        ) {
            return res.status(401).json({
                message: "Invalid token payload"
            });
        }

    } catch (error) {
        return res.status(401).json({
            message: "Invalid or expired token"
        });
    }

    // 3. Check user in database
    try {
        const [users] = await db.promise().query(
            `SELECT
                user_id,
                role,
                is_active
            FROM users
            WHERE user_id = ?
            LIMIT 1`,
            [payload.user_id]
        );

        if (users.length === 0) {
            return res.status(401).json({
                message: "User not found"
            });
        }

        const user = users[0];

        // 4. Check account status
        if (Number(user.is_active) !== 1) {
            return res.status(403).json({
                message: "Your account is inactive"
            });
        }

        // 5. Use current database role
        req.user = {
            user_id: user.user_id,
            role: user.role
        };

        return next();

    } catch (error) {
        console.error("Verify Token Error:", error);

        return res.status(500).json({
            message: "Authentication service error"
        });
    }
}


// Verify Admin Role
function verifyAdmin(req, res, next) {
    if (!req.user) {
        return res.status(401).json({
            message: "Authentication required"
        });
    }

    if (req.user.role !== 'admin') {
        return res.status(403).json({
            message: "Admin access required"
        });
    }
    return next();
}

module.exports = { verifyToken, verifyAdmin };
