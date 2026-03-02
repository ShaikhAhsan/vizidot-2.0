const express = require('express');
const router = express.Router();
const OrderController = require('../controllers/orderController');
const ChatController = require('../controllers/chatController');
const { authenticateToken, requireBusinessOwner, optionalAuth } = require('../middleware/auth');

const orderController = new OrderController();
const chatController = new ChatController();

// Public routes (with optional auth for guest users)
router.get('/public/:orderId', optionalAuth, orderController.getOrderDetails);

// Protected routes
router.use(authenticateToken);

// Order management routes
router.post('/', orderController.createOrder);
router.get('/user', orderController.getUserOrders);
router.get('/:orderId', orderController.getOrderDetails);
router.get('/:orderId/updates', orderController.getOrderUpdates);

// Business owner routes
router.get('/business/orders', requireBusinessOwner, orderController.getBusinessOrders);
router.put('/:orderId/status', requireBusinessOwner, orderController.updateOrderStatus);

// Chat routes
router.post('/:orderId/chat/message', chatController.sendMessage);
router.get('/:orderId/chat/messages', chatController.getChatMessages);
router.get('/:orderId/chat/history', chatController.getChatHistory);
router.post('/:orderId/chat/read', chatController.markAsRead);
router.get('/chat/list', chatController.getChatList);

module.exports = router;

