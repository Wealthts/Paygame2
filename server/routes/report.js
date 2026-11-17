
const express = require('express');
const router = express.Router();

const reportController = require('../controller/report_controller');

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// Summary cards
router.get(
    '/summary',
    verifyToken,
    verifyAdmin,
    reportController.getSummary
);

// Monthly revenue
router.get(
    '/monthly-revenue',
    verifyToken,
    verifyAdmin,
    reportController.getMonthlyRevenue
);

// Top 5 games
router.get(
    '/top-games',
    verifyToken,
    verifyAdmin,
    reportController.getTopGames
);

// Order statuses
router.get(
    '/order-statuses',
    verifyToken,
    verifyAdmin,
    reportController.getOrderStatuses
);

module.exports = router;
