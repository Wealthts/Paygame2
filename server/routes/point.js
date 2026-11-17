
const express = require('express');
const router = express.Router();

const {
    getMyPoints,
    getMyPointHistory,
    getAllPointTransactions,
    getPointTransactionById,
    createPointTransaction,
    updatePointTransaction,
    deletePointTransaction
} = require('../controller/point_controller');

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// User: View own point balance
router.get('/my-points', verifyToken, getMyPoints);

// User: View own point history
router.get('/history', verifyToken, getMyPointHistory);

// Admin: View all point transactions
router.get('/all', verifyToken, verifyAdmin, getAllPointTransactions);

// Admin: View point transaction by ID
router.get('/:id', verifyToken, verifyAdmin, getPointTransactionById);

// Admin: Create point transaction
router.post('/', verifyToken, verifyAdmin, createPointTransaction);

// Admin: Update point transaction
router.put('/:id', verifyToken, verifyAdmin, updatePointTransaction);

// Admin: Delete point transaction
router.delete('/:id', verifyToken, verifyAdmin, deletePointTransaction);

module.exports = router;
