
const express = require('express');
const router = express.Router();

const packageController = require('../controller/package_controller');

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// User: ดู Package ที่เปิดใช้งาน
router.get(
    '/',
    verifyToken,
    packageController.getAllPackages
);

// Admin: ดู Package ทั้งหมด
// ต้องวางก่อน /:id
router.get(
    '/all',
    verifyToken,
    verifyAdmin,
    packageController.getAllPackagesAdmin
);

// User/Admin: ดู Package ตาม ID
router.get(
    '/:id',
    verifyToken,
    packageController.getPackageById
);

// Admin: สร้าง Package
router.post(
    '/',
    verifyToken,
    verifyAdmin,
    packageController.createPackage
);

// Admin: แก้ไข Package
router.put(
    '/:id',
    verifyToken,
    verifyAdmin,
    packageController.updatePackage
);

// Admin: ปิดใช้งาน Package
router.patch(
    '/:id',
    verifyToken,
    verifyAdmin,
    packageController.softDeletePackage
);

// Admin: ลบ Package จริง
router.delete(
    '/:id',
    verifyToken,
    verifyAdmin,
    packageController.hardDeletePackage
);

module.exports = router;
