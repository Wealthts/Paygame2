const express = require('express');
const router = express.Router();
const authController = require('../controller/auth_controller');

// Register
router.post('/register', authController.register);

// Login
router.post('/login', authController.login);

// Forgot password (OTP via email)
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

module.exports = router;
