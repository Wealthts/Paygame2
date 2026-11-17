const express = require('express');
const router = express.Router();

const paymentController = require('../controller/payment_controller');

const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Admin: Get all payments
router.get('/all', verifyToken, verifyAdmin, paymentController.getAllPayments);

// User: Get own payments
router.get('/my-payments', verifyToken, paymentController.getMyPayments);

// Admin: Get payment by ID
router.get('/:id', verifyToken, verifyAdmin, paymentController.getPaymentById);

// User: Create payment
router.post('/', verifyToken, paymentController.createPayment);

// Admin: Update payment status
router.patch('/:id', verifyToken, verifyAdmin, paymentController.updatePayment);

// Admin: Cancel payment
router.delete('/:id', verifyToken, verifyAdmin, paymentController.deletePayment);

module.exports = router;