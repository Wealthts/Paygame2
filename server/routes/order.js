const express = require('express');
const router = express.Router();

const orderController = require('../controller/order_controller');

const { verifyToken, verifyAdmin } = require('../middleware/auth');

// Admin: Get all orders
router.get('/all', verifyToken, verifyAdmin, orderController.getAllOrders);

// User: Get own orders
router.get('/my-orders', verifyToken, orderController.getMyOrders);

// Admin: Get order by ID
router.get('/:id', verifyToken, verifyAdmin, orderController.getOrderById);

// User: Create order
router.post('/', verifyToken, orderController.createOrder);

// Admin: Update order status
router.put('/:id', verifyToken, verifyAdmin, orderController.updateOrder);

// User: Cancel own order
router.delete('/my-orders/:id', verifyToken, orderController.cancelMyOrder);

// Admin: Cancel order
router.delete('/:id', verifyToken, verifyAdmin, orderController.deleteOrder);

module.exports = router;