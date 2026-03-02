const express = require('express');
const router = express.Router();
const { authenticateToken, requireRole } = require('../middleware/auth');
const { User } = require('../models');

// Apply authentication to all routes
router.use(authenticateToken);

/**
 * Get user profile
 */
router.get('/profile', async (req, res) => {
  try {
    res.json({
      success: true,
      data: req.user.toJSON()
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Update user profile
 */
router.put('/profile', async (req, res) => {
  try {
    const allowedFields = ['first_name', 'last_name', 'phone', 'profile_image', 'address', 'preferences'];
    const updateData = {};
    
    for (const field of allowedFields) {
      if (req.body[field] !== undefined) {
        updateData[field] = req.body[field];
      }
    }

    await req.user.update(updateData);

    res.json({
      success: true,
      data: req.user.toJSON()
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get user statistics
 */
router.get('/stats', async (req, res) => {
  try {
    const { Order, Review } = require('../models');
    
    const [totalOrders, totalReviews] = await Promise.all([
      Order.count({ where: { user_id: req.user.id } }),
      Review.count({ where: { user_id: req.user.id } })
    ]);

    res.json({
      success: true,
      data: {
        totalOrders,
        totalReviews,
        memberSince: req.user.created_at
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Deactivate account
 */
router.put('/deactivate', async (req, res) => {
  try {
    await req.user.update({ is_active: false });

    res.json({
      success: true,
      message: 'Account deactivated successfully'
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Reactivate account
 */
router.put('/reactivate', async (req, res) => {
  try {
    await req.user.update({ is_active: true });

    res.json({
      success: true,
      message: 'Account reactivated successfully'
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

