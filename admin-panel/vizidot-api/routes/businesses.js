const express = require('express');
const router = express.Router();
const { authenticateToken, requireBusinessOwnership, optionalAuth } = require('../middleware/authWithRoles');
const { Business, BusinessTiming, Category, Product, Order } = require('../models');
const { Op } = require('sequelize');

// Public routes
router.get('/public', optionalAuth, async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', business_type, is_open } = req.query;
    const offset = (page - 1) * limit;
    
    const whereClause = { is_active: true, is_verified: true, is_delete: false };
    
    if (search) {
      whereClause[Op.or] = [
        { business_name: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } }
      ];
    }
    
    if (business_type) {
      whereClause.business_type = business_type;
    }
    
    const businesses = await Business.findAndCountAll({
      where: whereClause,
      include: [
        { model: BusinessTiming, as: 'timings' }
      ],
      limit: parseInt(limit),
      offset: offset,
      order: [['rating', 'DESC'], ['total_reviews', 'DESC']]
    });
    
    res.json({
      success: true,
      data: businesses.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: businesses.count,
        totalPages: Math.ceil(businesses.count / limit)
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

router.get('/public/:id', optionalAuth, async (req, res) => {
  try {
    const business = await Business.findOne({
      where: { 
        id: req.params.id,
        is_active: true,
        is_delete: false 
      },
      include: [
        { model: BusinessTiming, as: 'timings' },
        { model: Category, as: 'categories', where: { is_active: true }, required: false },
        { model: Product, as: 'products', where: { is_active: true }, required: false, limit: 20 }
      ]
    });
    
    if (!business) {
      return res.status(404).json({
        success: false,
        error: 'Business not found'
      });
    }
    
    res.json({
      success: true,
      data: business
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

// Protected routes
router.use(authenticateToken);

/**
 * Get user's businesses
 */
router.get('/', async (req, res) => {
  try {
    const businesses = await Business.findAll({
      where: { user_id: req.user.id, is_delete: false },
      include: [
        { model: BusinessTiming, as: 'timings' }
      ],
      order: [['created_at', 'DESC']]
    });
    
    res.json({
      success: true,
      data: businesses
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Create new business
 */
router.post('/', async (req, res) => {
  try {
    const businessData = {
      ...req.body,
      user_id: req.user.id
    };
    
    const business = await Business.create(businessData);
    
    // Create default business timings
    const timings = [];
    for (let day = 0; day < 7; day++) {
      timings.push({
        business_id: business.id,
        day_of_week: day,
        opening_time: '09:00',
        closing_time: '21:00',
        is_24_hours: false,
        is_closed: day === 0, // Closed on Sunday by default
        next_day_delivery_available: true
      });
    }
    
    await BusinessTiming.bulkCreate(timings);
    
    const completeBusiness = await Business.findByPk(business.id, {
      include: [
        { model: BusinessTiming, as: 'timings' }
      ]
    });
    
    res.status(201).json({
      success: true,
      data: completeBusiness
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get business details
 */
router.get('/:id', requireBusinessOwnership, async (req, res) => {
  try {
    const business = await Business.findByPk(req.params.id, {
      include: [
        { model: BusinessTiming, as: 'timings' },
        { model: Category, as: 'categories' },
        { model: Product, as: 'products', limit: 10 }
      ]
    });
    if (!business || business.is_delete) {
      return res.status(404).json({ success: false, error: 'Business not found' });
    }
    
    res.json({
      success: true,
      data: business
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Update business
 */
router.put('/:id', requireBusinessOwnership, async (req, res) => {
  try {
    await req.business.update(req.body);
    
    const updatedBusiness = await Business.findByPk(req.params.id, {
      include: [
        { model: BusinessTiming, as: 'timings' }
      ]
    });
    
    res.json({
      success: true,
      data: updatedBusiness
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Update business timings
 */
router.put('/:id/timings', requireBusinessOwnership, async (req, res) => {
  try {
    const { timings } = req.body;
    
    if (!Array.isArray(timings)) {
      return res.status(400).json({
        success: false,
        error: 'Timings must be an array'
      });
    }
    
    // Delete existing timings
    await BusinessTiming.destroy({
      where: { business_id: req.params.id }
    });
    
    // Create new timings
    const timingData = timings.map(timing => ({
      ...timing,
      business_id: req.params.id
    }));
    
    await BusinessTiming.bulkCreate(timingData);
    
    const updatedBusiness = await Business.findByPk(req.params.id, {
      include: [
        { model: BusinessTiming, as: 'timings' }
      ]
    });
    
    res.json({
      success: true,
      data: updatedBusiness
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get business statistics
 */
router.get('/:id/stats', requireBusinessOwnership, async (req, res) => {
  try {
    const [totalProducts, totalOrders, totalRevenue, totalCategories] = await Promise.all([
      Product.count({ where: { business_id: req.params.id } }),
      Order.count({ where: { business_id: req.params.id } }),
      Order.sum('total_amount', { where: { business_id: req.params.id } }),
      Category.count({ where: { business_id: req.params.id } })
    ]);
    
    // Recent orders
    const recentOrders = await Order.findAll({
      where: { business_id: req.params.id },
      include: [
        { model: User, as: 'user' }
      ],
      order: [['created_at', 'DESC']],
      limit: 10
    });
    
    res.json({
      success: true,
      data: {
        overview: {
          totalProducts,
          totalOrders,
          totalRevenue: totalRevenue || 0,
          totalCategories,
          rating: req.business.rating,
          totalReviews: req.business.total_reviews
        },
        recentOrders
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
 * Delete business (soft delete)
 */
router.delete('/:id', requireBusinessOwnership, async (req, res) => {
  try {
    // Soft delete via is_delete flag
    // No need to check for active orders since this is just marking as deleted
    await req.business.update({ 
      is_delete: true,
      is_active: false 
    });
    
    res.json({
      success: true,
      message: 'Business deleted successfully'
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

