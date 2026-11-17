const db = require('../db_config');

function isValidId(value) {
    const id = Number(value);

    return Number.isInteger(id) && id > 0;
}

// Get logged-in user's profile
async function getProfile(req, res) {
    try {
        const userId = req.user.user_id;
        const [users] = await db.promise().query(
            `SELECT user_id, username, email, display_name, role
             FROM users
             WHERE user_id = ?`,
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        return res.status(200).json({
            user: users[0]
        });

    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Get all users (Admin only)
async function getAllUsers(req, res) {
    try {
        const [users] = await db.promise().query(
            `SELECT user_id, username, email, display_name, role, is_active
             FROM users`
        );

        return res.status(200).json({
            users: users
        });

    } catch (error) {
        console.error(error);

        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Update user
async function updateUser(req, res) {
    const userId = Number(req.params.id);
    const body = req.body || {};

    if (!isValidId(userId)) {
        return res.status(400).json({
            message: 'Invalid user ID'
        });
    }

    const username =
        typeof body.username === 'string'
            ? body.username.trim()
            : '';

    const email =
        typeof body.email === 'string'
            ? body.email.trim().toLowerCase()
            : '';

    const display_name =
        typeof body.display_name === 'string'
            ? body.display_name.trim()
            : '';

    const role = body.role;

    const is_active =
        body.is_active === true || body.is_active === 1 ||
            body.is_active === '1'
            ? 1
            : body.is_active === false || body.is_active === 0 ||
                body.is_active === '0'
                ? 0
                : null;

    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (
        !username || username.length > 100 ||
        !email || email.length > 100 ||
        !emailPattern.test(email) ||
        !display_name || display_name.length > 100 ||
        !['admin', 'user'].includes(role) ||
        is_active === null
    ) {
        return res.status(400).json({
            message: 'Please provide valid user information'
        });
    }
    try {
        const { username, email, display_name, role, is_active } = req.body;

        // Check required fields
        if (
            !username || !email || !display_name ||
            !['admin', 'user'].includes(role) ||
            ![0, 1].includes(Number(is_active))
        ) {
            return res.status(400).json({
                message: "Please provide valid user information"
            });
        }

        // Check if user exists
        const [users] = await db.promise().query(
            "SELECT user_id FROM users WHERE user_id = ?",
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Check if username or email is already taken by another user
        const [duplicateUsers] = await db.promise().query(
            "SELECT user_id FROM users WHERE (username = ? OR email = ?) AND user_id != ?",
            [username, email, userId]
        );

        if (duplicateUsers.length > 0) {
            return res.status(409).json({
                message: "Username or email already exists"
            });
        }

        // Update user
        await db.promise().query(
            `UPDATE users
             SET username = ?,
                 email = ?,
                 display_name = ?,
                 role = ?,
                 is_active = ?
             WHERE user_id = ?`,
            [
                username,
                email,
                display_name,
                role,
                Number(is_active),
                userId
            ]
        );

        return res.status(200).json({
            message: "User updated successfully"
        });

    } catch (error) {
        console.error(error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({
                message: "Username or email already exists"
            });
        }

        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Delete user (Soft Delete)
async function softDeleteUser(req, res) {

    const userId = Number(req.params.id);

    if (!isValidId(userId)) {
        return res.status(400).json({
            message: 'Invalid user ID'
        });
    }
    try {
        // Check if user exists
        const [users] = await db.promise().query(
            "SELECT user_id FROM users WHERE user_id = ?",
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Deactivate user
        await db.promise().query(
            "UPDATE users SET is_active = 0 WHERE user_id = ?",
            [userId]
        );

        return res.status(200).json({
            message: "User deactivated successfully"
        });

    } catch (error) {
        console.error(error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

// Delete user (Hard Delete)
async function hardDeleteUser(req, res) {

    const userId = Number(req.params.id);

    if (!isValidId(userId)) {
        return res.status(400).json({
            message: 'Invalid user ID'
        });
    }

    try {
        // Check if user exists
        const [users] = await db.promise().query(
            "SELECT user_id FROM users WHERE user_id = ?",
            [userId]
        );

        if (users.length === 0) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Hard delete user
        await db.promise().query(
            "DELETE FROM users WHERE user_id = ?",
            [userId]
        );

        return res.status(200).json({
            message: "User deleted successfully"
        });

    } catch (error) {
        if (
            error.code === 'ER_ROW_IS_REFERENCED_2' ||
            error.code === 'ER_ROW_IS_REFERENCED'
        ) {
            return res.status(409).json({
                message: 'Cannot delete user because this user has related records'
            });
        }

        console.error(error);
        return res.status(500).json({
            message: "Internal server error"
        });
    }
}

module.exports = { getProfile, getAllUsers, updateUser, softDeleteUser, hardDeleteUser };