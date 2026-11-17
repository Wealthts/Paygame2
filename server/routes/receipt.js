
const express = require('express');
const router = express.Router();

const {
    createReceipt,
    getAllReceipts,
    getReceiptById,
    getMyReceipts
} = require('../controller/receipt_controller');

const {
    verifyToken,
    verifyAdmin
} = require('../middleware/auth');

// Admin: Create receipt
router.post('/', verifyToken, verifyAdmin, createReceipt);

// Admin: View all receipts
router.get('/all', verifyToken, verifyAdmin, getAllReceipts);

// User: View own receipts
router.get('/my-receipts', verifyToken, getMyReceipts);

// User/Admin: View receipt by ID
router.get('/:id', verifyToken, getReceiptById);

module.exports = router;
