
const express = require('express');
const router = express.Router();

const packageAdminController = require(
    '../controller/package_admin_controller'
);

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// ทุก Route ต้องเป็น Admin
router.use(verifyToken, verifyAdmin);

// GET /api/admin/packages
router.get('/', packageAdminController.getAllPackages);

// POST /api/admin/packages
router.post('/', packageAdminController.createPackage);

// PUT /api/admin/packages/:id
router.put('/:id', packageAdminController.updatePackage);

// PATCH /api/admin/packages/:id/status
router.patch(
    '/:id/status',
    packageAdminController.updatePackageStatus
);

module.exports = router;
