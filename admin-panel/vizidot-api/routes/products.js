const express = require('express');
const router = express.Router();
const { authenticateToken, requireBusinessOwner, optionalAuth } = require('../middleware/auth');
const { Product, Category, Business, Review } = require('../models');
const { Op } = require('sequelize');

// Public routes
router.get('/public', optionalAuth, async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 20, 
      search = '', 
      category_id, 
      business_id, 
      min_price, 
      max_price,
      sort_by = 'created_at',
      sort_order = 'DESC'
    } = req.query;
    
    const offset = (page - 1) * limit;
    const whereClause = { is_active: true, is_verified: true };
    
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
        { tags: { [Op.like]: `%${search}%` } }
      ];
    }
    
    if (category_id) {
      whereClause.category_id = category_id;
    }
    
    if (business_id) {
      whereClause.business_id = business_id;
    }
    
    if (min_price || max_price) {
      whereClause.price = {};
      if (min_price) whereClause.price[Op.gte] = parseFloat(min_price);
      if (max_price) whereClause.price[Op.lte] = parseFloat(max_price);
    }
    
    const products = await Product.findAndCountAll({
      where: whereClause,
      include: [
        { model: Business, as: 'business' },
        { model: Category, as: 'category' }
      ],
      limit: parseInt(limit),
      offset: offset,
      order: [[sort_by, sort_order.toUpperCase()]]
    });
    
    res.json({
      success: true,
      data: products.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: products.count,
        totalPages: Math.ceil(products.count / limit)
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
    const product = await Product.findOne({
      where: { 
        id: req.params.id,
        is_active: true 
      },
      include: [
        { model: Business, as: 'business' },
        { model: Category, as: 'category' },
        { 
          model: Review, 
          as: 'reviews', 
          where: { is_approved: true },
          required: false,
          limit: 10,
          order: [['created_at', 'DESC']]
        }
      ]
    });
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    res.json({
      success: true,
      data: product
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
 * Get business products
 */
router.get('/business/:businessId', requireBusinessOwner, async (req, res) => {
  try {
    const { page = 1, limit = 20, search = '', category_id, is_active } = req.query;
    const offset = (page - 1) * limit;
    
    const whereClause = { business_id: req.params.businessId };
    
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { description: { [Op.like]: `%${search}%` } },
        { sku: { [Op.like]: `%${search}%` } }
      ];
    }
    
    if (category_id) {
      whereClause.category_id = category_id;
    }
    
    if (is_active !== undefined) {
      whereClause.is_active = is_active === 'true';
    }
    
    const products = await Product.findAndCountAll({
      where: whereClause,
      include: [
        { model: Category, as: 'category' }
      ],
      limit: parseInt(limit),
      offset: offset,
      order: [['created_at', 'DESC']]
    });
    
    res.json({
      success: true,
      data: products.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: products.count,
        totalPages: Math.ceil(products.count / limit)
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
 * Create new product
 */
router.post('/business/:businessId', requireBusinessOwner, async (req, res) => {
  try {
    const productData = {
      ...req.body,
      business_id: req.params.businessId
    };
    
    // Validate category belongs to business
    if (productData.category_id) {
      const category = await Category.findOne({
        where: {
          id: productData.category_id,
          business_id: req.params.businessId
        }
      });
      
      if (!category) {
        return res.status(400).json({
          success: false,
          error: 'Category not found or does not belong to this business'
        });
      }
    }
    
    const product = await Product.create(productData);
    
    // Generate SKU if not provided
    if (!product.sku) {
      const sku = `BUS${product.business_id}-PROD${product.id}`;
      await product.update({ sku });
    }
    
    const completeProduct = await Product.findByPk(product.id, {
      include: [
        { model: Category, as: 'category' }
      ]
    });
    
    res.status(201).json({
      success: true,
      data: completeProduct
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Get product details
 */
router.get('/:id', async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [
        { model: Business, as: 'business' },
        { model: Category, as: 'category' }
      ]
    });
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Check if user has access to this product
    if (req.user.user_type !== 'admin' && product.business.user_id !== req.user.id) {
      // Only show active products to non-owners
      if (!product.is_active) {
        return res.status(404).json({
          success: false,
          error: 'Product not found'
        });
      }
    }
    
    res.json({
      success: true,
      data: product
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Update product
 */
router.put('/:id', async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Business, as: 'business' }]
    });
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Check if user has access to update this product
    if (req.user.user_type !== 'admin' && product.business.user_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    // Validate category if provided
    if (req.body.category_id) {
      const category = await Category.findOne({
        where: {
          id: req.body.category_id,
          business_id: product.business_id
        }
      });
      
      if (!category) {
        return res.status(400).json({
          success: false,
          error: 'Category not found or does not belong to this business'
        });
      }
    }
    
    await product.update(req.body);
    
    const updatedProduct = await Product.findByPk(req.params.id, {
      include: [
        { model: Category, as: 'category' }
      ]
    });
    
    res.json({
      success: true,
      data: updatedProduct
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Update product stock
 */
router.put('/:id/stock', async (req, res) => {
  try {
    const { quantity, operation = 'set' } = req.body;
    
    if (typeof quantity !== 'number' || quantity < 0) {
      return res.status(400).json({
        success: false,
        error: 'Valid quantity is required'
      });
    }
    
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Business, as: 'business' }]
    });
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Check if user has access to update this product
    if (req.user.user_type !== 'admin' && product.business.user_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    let newStock;
    if (operation === 'add') {
      newStock = product.stock_quantity + quantity;
    } else if (operation === 'subtract') {
      newStock = Math.max(0, product.stock_quantity - quantity);
    } else {
      newStock = quantity;
    }
    
    await product.update({ stock_quantity: newStock });
    
    res.json({
      success: true,
      data: {
        id: product.id,
        stock_quantity: newStock,
        is_low_stock: newStock <= product.min_stock_alert
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
 * Delete product
 */
router.delete('/:id', async (req, res) => {
  try {
    const product = await Product.findByPk(req.params.id, {
      include: [{ model: Business, as: 'business' }]
    });
    
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Check if user has access to delete this product
    if (req.user.user_type !== 'admin' && product.business.user_id !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'Access denied'
      });
    }
    
    await product.destroy();
    
    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

/**
 * Bulk update products
 */
router.put('/bulk-update', async (req, res) => {
  try {
    const { product_ids, updates } = req.body;
    
    if (!Array.isArray(product_ids) || product_ids.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Product IDs array is required'
      });
    }
    
    if (!updates || typeof updates !== 'object') {
      return res.status(400).json({
        success: false,
        error: 'Updates object is required'
      });
    }
    
    // Verify user has access to all products
    const products = await Product.findAll({
      where: { id: { [Op.in]: product_ids } },
      include: [{ model: Business, as: 'business' }]
    });
    
    for (const product of products) {
      if (req.user.user_type !== 'admin' && product.business.user_id !== req.user.id) {
        return res.status(403).json({
          success: false,
          error: `Access denied for product ${product.id}`
        });
      }
    }
    
    const [updatedCount] = await Product.update(updates, {
      where: { id: { [Op.in]: product_ids } }
    });
    
    res.json({
      success: true,
      message: `${updatedCount} products updated successfully`
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

