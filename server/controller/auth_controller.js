
const db = require('../db_config');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { sendOtpEmail } = require('../utils/mailer');

const OTP_EXPIRES_MINUTES = 10;
const OTP_RESEND_SECONDS = 60;
const OTP_MAX_ATTEMPTS = 5;

// Register
const register = async (req, res) => {
    try {
        const { username, password, email, display_name, accepted_terms } = req.body || {};

        // 1. Validate required fields
        if (
            typeof username !== 'string' || !username.trim() ||
            typeof password !== 'string' || !password ||
            typeof email !== 'string' || !email.trim() ||
            typeof display_name !== 'string' || !display_name.trim()
        ) { return res.status(400).json({ message: "Please fill in all required fields" }); }

         // 1.1 Must accept Terms and Conditions
        if (accepted_terms !== true) {
            return res.status(400).json({
                message:
                    "Please accept the terms and conditions before signing up.",
            });
        }

        // 2. Clean input
        const cleanUsername = username.trim();
        const cleanEmail = email.trim().toLowerCase();
        const cleanDisplayName = display_name.trim();

        // 3. Check field lengths
        if (
            cleanUsername.length > 100 || cleanEmail.length > 100 ||
            cleanDisplayName.length > 100 || password.length < 8 ||
            password.length > 128
        ) { return res.status(400).json({ message: "Invalid registration data" }); }

        // 4. Basic email validation
        const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

        if (!emailPattern.test(cleanEmail)) {
            return res.status(400).json({
                message: "Invalid email address"
            });
        }

        // 5. Check duplicate username or email
        const [existingUsers] = await db.promise().query(
            `SELECT user_id
             FROM users
             WHERE username = ? OR email = ?
             LIMIT 1`,
            [cleanUsername, cleanEmail]
        );

        if (existingUsers.length > 0) {
            return res.status(409).json({
                message: "Username or email already exists"
            });
        }

        // 6. Hash password
        const hashedPassword = await argon2.hash(password);

        // 7. Insert user
        const [result] = await db.promise().query(
            `INSERT INTO users (
                username, password_hash,
                email, display_name,
                is_active, role
            )
            VALUES (?, ?, ?, ?, ?, ?)`,
            [
                cleanUsername, hashedPassword,
                cleanEmail, cleanDisplayName,
                1, 'user'
            ]
        );

        return res.status(201).json({
            message: "Register successful",
            user_id: result.insertId
        });

    } catch (error) {
        console.error('Register Error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: "Username or email already exists"
            });
        }

        return res.status(500).json({
            message: "Register failed"
        });
    }
};


// Login
const login = async (req, res) => {
    try {
        const { username, password } = req.body || {};

        // 1. Validate input
        if (
            typeof username !== 'string' || !username.trim() ||
            typeof password !== 'string' || !password
        ) {
            return res.status(400).json({
                message: 'Please enter username and password'
            });
        }

        // 2. Find user
        const [users] = await db.promise().query(
            `SELECT
                user_id, username,
                password_hash, email,
                display_name, role,
                is_active
            FROM users
            WHERE username = ?
            LIMIT 1`,
            [username.trim()]
        );

        if (users.length === 0) {
            return res.status(401).json({
                message: "Invalid username or password"
            });
        }

        const user = users[0];

        // 3. Check account status
        if (Number(user.is_active) !== 1) {
            return res.status(403).json({
                message: "Your account is inactive"
            });
        }

        // 4. Verify password
        const isPasswordValid = await argon2.verify(
            user.password_hash,
            password
        );

        if (!isPasswordValid) {
            return res.status(401).json({
                message: "Invalid username or password"
            });
        }

        // 5. Generate JWT
        const token = jwt.sign(
            { user_id: user.user_id, role: user.role },
            process.env.JWT_KEY,
            { expiresIn: process.env.JWT_EXPIRES_IN || '1d' }
        );

        // 6. Return response
        return res.status(200).json({
            message: 'Login successful',
            token: token,
            user: {
                user_id: user.user_id,
                username: user.username,
                email: user.email,
                display_name: user.display_name,
                role: user.role
            }
        });

    } catch (error) {
        console.error('Login Error:', error);

        return res.status(500).json({
            message: 'Login failed'
        });
    }
};



// ========================================
// Forgot Password helpers
// ========================================
function hashOtp(userId, otp) {
    return crypto
        .createHmac('sha256', process.env.JWT_KEY)
        .update(`${userId}:${otp}`)
        .digest('hex');
}

const GENERIC_FORGOT_MESSAGE =
    'If this email exists in our system, we have sent an OTP code.';

// Step 1: request OTP
const forgotPassword = async (req, res) => {
    try {
        const { email } = req.body || {};

        if (typeof email !== 'string' || !email.trim()) {
            return res.status(400).json({ message: 'Please enter your email' });
        }

        const cleanEmail = email.trim().toLowerCase();

        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail) || cleanEmail.length > 100) {
            return res.status(400).json({ message: 'Invalid email format' });
        }

        const [users] = await db.promise().query(
            `SELECT user_id, display_name, email
             FROM users
             WHERE email = ? AND is_active = 1
             LIMIT 1`,
            [cleanEmail]
        );

        // Same answer whether or not the email exists (prevents account enumeration)
        if (users.length === 0) {
            return res.status(200).json({ message: GENERIC_FORGOT_MESSAGE });
        }

        const user = users[0];

        // Resend cooldown
        const [recent] = await db.promise().query(
            `SELECT reset_id FROM password_resets
             WHERE user_id = ?
               AND created_at > (NOW() - INTERVAL ${OTP_RESEND_SECONDS} SECOND)
             LIMIT 1`,
            [user.user_id]
        );

        if (recent.length > 0) {
            return res.status(200).json({ message: GENERIC_FORGOT_MESSAGE });
        }

        // Generate 6-digit OTP with a cryptographically secure RNG
        const otp = crypto.randomInt(0, 1000000).toString().padStart(6, '0');

        // Invalidate old unused OTPs, then store the new one (hash only)
        await db.promise().query(
            `UPDATE password_resets SET used_at = NOW()
             WHERE user_id = ? AND used_at IS NULL`,
            [user.user_id]
        );

        const [insert] = await db.promise().query(
            `INSERT INTO password_resets (user_id, otp_hash, expires_at)
             VALUES (?, ?, NOW() + INTERVAL ${OTP_EXPIRES_MINUTES} MINUTE)`,
            [user.user_id, hashOtp(user.user_id, otp)]
        );

        try {
            await sendOtpEmail({
                to: user.email,
                otp,
                displayName: user.display_name,
                expiresMinutes: OTP_EXPIRES_MINUTES
            });
        } catch (mailError) {
            console.error('Send OTP Email Error:', mailError);
            await db.promise().query(
                'DELETE FROM password_resets WHERE reset_id = ?',
                [insert.insertId]
            );
            return res.status(500).json({
                message: 'Failed to send email. Please try again'
            });
        }

        return res.status(200).json({ message: GENERIC_FORGOT_MESSAGE });

    } catch (error) {
        console.error('Forgot Password Error:', error);
        return res.status(500).json({ message: 'Unable to process request. Please try again' });
    }
};

// Step 2: verify OTP + set new password
const resetPassword = async (req, res) => {
    try {
        const { email, otp, new_password } = req.body || {};

        if (
            typeof email !== 'string' || !email.trim() ||
            typeof otp !== 'string' || typeof new_password !== 'string'
        ) {
            return res.status(400).json({ message: 'Please fill in all required fields' });
        }

        if (!/^\d{6}$/.test(otp)) {
            return res.status(400).json({ message: 'OTP code must be 6 digits' });
        }

        if (new_password.length < 8 || new_password.length > 128) {
            return res.status(400).json({
                message: 'Password must be 8–128 characters long'
            });
        }

        const INVALID_OTP = { message: 'Invalid or expired OTP code' };
        const cleanEmail = email.trim().toLowerCase();

        const [users] = await db.promise().query(
            `SELECT user_id FROM users
             WHERE email = ? AND is_active = 1
             LIMIT 1`,
            [cleanEmail]
        );

        if (users.length === 0) {
            return res.status(400).json(INVALID_OTP);
        }

        const userId = users[0].user_id;

        // Latest unused, unexpired OTP
        const [resets] = await db.promise().query(
            `SELECT reset_id, otp_hash, attempts
             FROM password_resets
             WHERE user_id = ? AND used_at IS NULL AND expires_at > NOW()
             ORDER BY reset_id DESC
             LIMIT 1`,
            [userId]
        );

        if (resets.length === 0) {
            return res.status(400).json(INVALID_OTP);
        }

        const reset = resets[0];

        if (reset.attempts >= OTP_MAX_ATTEMPTS) {
            await db.promise().query(
                'UPDATE password_resets SET used_at = NOW() WHERE reset_id = ?',
                [reset.reset_id]
            );
            return res.status(429).json({
                message: 'Too many invalid OTP attempts. Please request a new code'
            });
        }

        const expected = Buffer.from(reset.otp_hash, 'hex');
        const actual = Buffer.from(hashOtp(userId, otp), 'hex');

        if (expected.length !== actual.length || !crypto.timingSafeEqual(expected, actual)) {
            await db.promise().query(
                'UPDATE password_resets SET attempts = attempts + 1 WHERE reset_id = ?',
                [reset.reset_id]
            );
            return res.status(400).json(INVALID_OTP);
        }

        // Claim the OTP atomically so it can only be used once
        const [claim] = await db.promise().query(
            `UPDATE password_resets SET used_at = NOW()
             WHERE reset_id = ? AND used_at IS NULL`,
            [reset.reset_id]
        );

        if (claim.affectedRows !== 1) {
            return res.status(400).json(INVALID_OTP);
        }

        const hashedPassword = await argon2.hash(new_password);

        await db.promise().query(
            'UPDATE users SET password_hash = ? WHERE user_id = ?',
            [hashedPassword, userId]
        );

        return res.status(200).json({ message: 'Password changed successfully' });

    } catch (error) {
        console.error('Reset Password Error:', error);
        return res.status(500).json({ message: 'Unable to change password' });
    }
};

module.exports = { register, login, forgotPassword, resetPassword };
