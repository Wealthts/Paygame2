
const express = require('express');
const router = express.Router();

const userAdminController = require(
    '../controller/user_admin_controller'
);

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// Admin: Get all members
router.get(
    '/all',
    verifyToken,
    verifyAdmin,
    userAdminController.getAllUsers
);

// Admin: Enable / Disable member account
router.patch(
    '/:id/status',
    verifyToken,
    verifyAdmin,
    userAdminController.updateUserStatus
);

// Admin: Get member details and history
router.get(
    '/:id/details',
    verifyToken,
    verifyAdmin,
    userAdminController.getUserDetails
);

module.exports = router;
