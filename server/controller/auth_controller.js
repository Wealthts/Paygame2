
const db = require('../db_config');
const argon2 = require('@node-rs/argon2');
const jwt = require('jsonwebtoken');

// Register
const register = async (req, res) => {
    try {
        const { username, password, email, display_name } = req.body || {};

        // 1. Validate required fields
        if (
            typeof username !== 'string' || !username.trim() ||
            typeof password !== 'string' || !password ||
            typeof email !== 'string' || !email.trim() ||
            typeof display_name !== 'string' || !display_name.trim()
        ) { return res.status(400).json({ message: "Please fill in all required fields" }); }

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

module.exports = { register, login };
