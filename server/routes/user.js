const express = require('express');
const router = express.Router();
const userController = require('../controller/user_controller');
const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Get logged-in user's profile
router.get('/profile', verifyToken, userController.getProfile);

// Get all users (Admin only)
router.get('/all', verifyToken, verifyAdmin, userController.getAllUsers);

// Update user (Admin only)
router.put('/:id', verifyToken, verifyAdmin, userController.updateUser);

// Delete user (Admin only) (Soft delete)
router.patch('/soft/:id', verifyToken, verifyAdmin, userController.softDeleteUser);

// Delete user (Admin only) (Hard delete)
router.delete('/hard/:id', verifyToken, verifyAdmin, userController.hardDeleteUser);

module.exports = router;