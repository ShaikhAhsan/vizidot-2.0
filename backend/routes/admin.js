const express = require('express');
const router = express.Router();
const { Op } = require('sequelize');
const CrudController = require('../controllers/crudController');
const { authenticateToken, requireSystemAdmin, requireSuperAdmin } = require('../middleware/authWithRoles');
const {
  User,
  Business,
  BusinessTiming,
  Category,
  Product,
  Order,
  OrderItem,
  Coupon,
  Review,
  Cart,
  CartItem,
  Brand,
  Tag,
  ProductTag,
  ProductCategory
} = require('../models');

const crud = new CrudController();

// Test endpoint without authentication
router.get('/test', async (req, res) => {
  try {
    const { Brand, Category, Tag } = require('../models');
    const brands = await Brand.findAll({ limit: 5 });
    const categories = await Category.findAll({ limit: 5 });
    const tags = await Tag.findAll({ limit: 5 });
    
    res.json({
      success: true,
      data: {
        brands: brands.length,
        categories: categories.length,
        tags: tags.length,
        brands_data: brands,
        categories_data: categories,
        tags_data: tags
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Debug endpoint for category association
router.get('/debug-product/:id', async (req, res) => {
  try {
    const { Product, Category } = require('../models');
    const { id } = req.params;
    
    const product = await Product.findByPk(id, {
      include: [{ 
        model: Category, 
        as: 'category',
        attributes: ['id', 'name', 'slug']
      }],
      attributes: ['id', 'name', 'category_id']
    });
    
    res.json({
      success: true,
      data: {
        product: product,
        raw_category: product.category,
        category_id: product.category_id
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Apply authentication and system admin role to all routes
router.use(authenticateToken);
router.use(requireSystemAdmin);

// Model-specific middleware
const setModel = (model, include = []) => (req, res, next) => {
  req.model = model;
  req.include = include;
  next();
};

// Business context middleware for filtering data
const setBusinessContext = (req, res, next) => {
  const businessId = req.headers['x-business-id'];
  
  // If business ID is provided, add it to the query
  if (businessId) {
    req.businessContext = businessId;
  }
  
  next();
};

// Users CRUD with role information
router.get('/users', setBusinessContext, async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', sortBy = 'created_at', sortOrder = 'DESC' } = req.query;
    const offset = (page - 1) * limit;
    
    // Build where clause for search
    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { first_name: { [Op.like]: `%${search}%` } },
        { last_name: { [Op.like]: `%${search}%` } },
        { email: { [Op.like]: `%${search}%` } }
      ];
    }
    
    // Add business context filtering if provided
    if (req.businessContext) {
      // For users, we might want to filter by users who have orders from this business
      // or users who are associated with this business
      whereClause.id = {
        [Op.in]: await User.findAll({
          attributes: ['id'],
          include: [{
            model: Order,
            as: 'orders',
            where: { business_id: req.businessContext },
            required: true
          }]
        }).then(users => users.map(u => u.id))
      };
    }
    
    const { count, rows: users } = await User.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit),
      offset: parseInt(offset),
      order: [[sortBy, sortOrder.toUpperCase()]],
      include: [
        {
          model: require('../models').Role,
          as: 'roles',
          through: { attributes: [] },
          required: false
        }
      ]
    });

    // Add role information and assigned artists to each user
    const usersWithRoles = await Promise.all(users.map(async (user) => {
      const userData = user.toJSON();
      
      // Get user roles
      const RBACService = require('../services/rbacService');
      const userRoles = await RBACService.getUserRoles(user.id);
      const highestRole = await RBACService.getUserHighestRole(user.id);
      
      userData.roles = userRoles;
      userData.role = highestRole?.name || userData.primary_role || 'customer';
      
      // Get assigned artists
      const { Artist, UserArtist } = require('../models');
      try {
        const userArtists = await UserArtist.findAll({
          where: { user_id: user.id },
          include: [{
            model: Artist,
            as: 'artist',
            required: false
          }]
        });
        userData.assignedArtists = userArtists.map(ua => ua.artist).filter(a => a);
      } catch (artistError) {
        console.error('Error fetching assigned artists:', artistError);
        userData.assignedArtists = [];
      }
      
      return userData;
    }));

    res.json({
      success: true,
      data: usersWithRoles,
      pagination: {
        total: count,
        page: parseInt(page),
        limit: parseInt(limit),
        pages: Math.ceil(count / limit)
      }
    });
  } catch (error) {
    console.error('Users list error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

router.get('/users/:id', setModel(User), crud.get);
router.post('/users', setModel(User), crud.create);
router.put('/users/:id', setModel(User), crud.update);
router.delete('/users/:id', setModel(User), crud.delete);

// User-Artist assignment endpoints
router.get('/users/:id/artists', async (req, res) => {
  try {
    const { User, Artist, UserArtist } = require('../models');
    const user = await User.findByPk(req.params.id, {
      include: [{
        model: Artist,
        as: 'artists',
        through: { attributes: [] }
      }]
    });
    
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    res.json({ success: true, data: user.artists || [] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

router.post('/users/:id/artists', async (req, res) => {
  try {
    const { User, Artist, UserArtist } = require('../models');
    const { artist_ids } = req.body;
    
    if (!Array.isArray(artist_ids)) {
      return res.status(400).json({ success: false, error: 'artist_ids must be an array' });
    }
    
    const user = await User.findByPk(req.params.id);
    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }
    
    // Validate artist IDs exist if provided
    if (artist_ids.length > 0) {
      const artists = await Artist.findAll({
        where: { artist_id: artist_ids },
        attributes: ['artist_id']
      });
      const validArtistIds = artists.map(a => a.artist_id);
      const invalidIds = artist_ids.filter(id => !validArtistIds.includes(id));
      
      if (invalidIds.length > 0) {
        return res.status(400).json({ 
          success: false, 
          error: `Invalid artist IDs: ${invalidIds.join(', ')}` 
        });
      }
    }
    
    // Remove existing assignments
    await UserArtist.destroy({ where: { user_id: parseInt(req.params.id) } });
    
    // Add new assignments
    if (artist_ids.length > 0) {
      const assignments = artist_ids.map(artist_id => ({
        user_id: parseInt(req.params.id),
        artist_id: parseInt(artist_id)
      }));
      
      await UserArtist.bulkCreate(assignments, {
        ignoreDuplicates: true
      });
    }
    
    // Fetch updated user with artists
    const updatedUser = await User.findByPk(req.params.id, {
      include: [{
        model: Artist,
        as: 'artists',
        through: { attributes: [] },
        required: false
      }]
    });
    
    if (!updatedUser) {
      return res.status(404).json({ success: false, error: 'User not found after update' });
    }
    
    res.json({ success: true, data: updatedUser.artists || [] });
  } catch (error) {
    console.error('Error assigning artists to user:', error);
    res.status(500).json({ success: false, error: error.message });
  }
});
router.post('/users/bulk-delete', setModel(User), crud.bulkDelete);
router.post('/users/bulk-update', setModel(User), crud.bulkUpdate);
router.get('/users/stats/overview', setModel(User), crud.getStats);

// Businesses CRUD
router.get('/businesses', setModel(Business, [{ model: User, as: 'owner' }]), crud.list);
router.get('/businesses/:id', setModel(Business, [{ model: User, as: 'owner' }]), crud.get);
router.post('/businesses', setModel(Business, [{ model: User, as: 'owner' }]), crud.create);
router.put('/businesses/:id', setModel(Business, [{ model: User, as: 'owner' }]), crud.update);
router.delete('/businesses/:id', setModel(Business), crud.delete);
router.post('/businesses/bulk-delete', setModel(Business), crud.bulkDelete);
router.post('/businesses/bulk-update', setModel(Business), crud.bulkUpdate);
router.get('/businesses/stats/overview', setModel(Business), crud.getStats);

// Business Timings CRUD
router.get('/business-timings', setModel(BusinessTiming, [{ model: Business, as: 'business' }]), crud.list);
router.get('/business-timings/:id', setModel(BusinessTiming, [{ model: Business, as: 'business' }]), crud.get);
router.post('/business-timings', setModel(BusinessTiming), crud.create);
router.put('/business-timings/:id', setModel(BusinessTiming), crud.update);
router.delete('/business-timings/:id', setModel(BusinessTiming), crud.delete);

// Categories CRUD with business context
router.get('/categories', setBusinessContext, setModel(Category, [{ model: Business, as: 'business' }]), crud.list);
router.get('/categories/:id', setBusinessContext, setModel(Category, [{ model: Business, as: 'business' }]), crud.get);
router.post('/categories', setBusinessContext, setModel(Category), crud.create);
router.put('/categories/:id', setBusinessContext, setModel(Category), crud.update);
router.delete('/categories/:id', setBusinessContext, setModel(Category), crud.delete);
router.post('/categories/bulk-delete', setBusinessContext, setModel(Category), crud.bulkDelete);
router.post('/categories/bulk-update', setBusinessContext, setModel(Category), crud.bulkUpdate);

// Category <-> Products association management
router.post('/categories/:id/assign-products', async (req, res) => {
  try {
    const { id } = req.params;
    const { product_ids } = req.body || {};
    if (!Array.isArray(product_ids) || product_ids.length === 0) {
      return res.status(400).json({ success: false, error: 'product_ids array is required' });
    }

    // Validate category exists
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    // Validate products exist
    const products = await Product.findAll({ where: { id: { [Op.in]: product_ids } }, attributes: ['id'] });
    const foundIds = products.map(p => p.id);
    const missing = product_ids.filter(pid => !foundIds.includes(pid));
    if (missing.length > 0) {
      return res.status(400).json({ success: false, error: `Products not found: ${missing.join(', ')}` });
    }

    // Create associations if not exist
    const existingRows = await ProductCategory.findAll({ where: { category_id: id, product_id: { [Op.in]: product_ids } }, attributes: ['product_id'] });
    const alreadyLinked = new Set(existingRows.map(r => r.product_id));
    const toCreate = product_ids.filter(pid => !alreadyLinked.has(pid)).map((pid, index) => ({
      product_id: pid,
      category_id: parseInt(id, 10),
      is_primary: false,
      sort_order: index
    }));
    if (toCreate.length > 0) {
      await ProductCategory.bulkCreate(toCreate);
    }

    return res.json({ success: true, data: { added: toCreate.length, skipped: product_ids.length - toCreate.length } });
  } catch (error) {
    return res.status(400).json({ success: false, error: error.message });
  }
});

router.post('/categories/:id/remove-products', async (req, res) => {
  try {
    const { id } = req.params;
    const { product_ids } = req.body || {};
    if (!Array.isArray(product_ids) || product_ids.length === 0) {
      return res.status(400).json({ success: false, error: 'product_ids array is required' });
    }

    // Ensure category exists
    const category = await Category.findByPk(id);
    if (!category) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    const deleted = await ProductCategory.destroy({ where: { category_id: id, product_id: { [Op.in]: product_ids } } });
    return res.json({ success: true, data: { removed: deleted } });
  } catch (error) {
    return res.status(400).json({ success: false, error: error.message });
  }
});

// Products CRUD with business context (custom list to support category filter)
router.get('/products', setBusinessContext, async (req, res) => {
  try {
    const { page = 1, limit = 10, search = '', sortBy = 'created_at', sortOrder = 'DESC', category_id } = req.query;
    const offset = (page - 1) * limit;

    const whereClause = {};
    if (search) {
      whereClause[Op.or] = [
        { name: { [Op.like]: `%${search}%` } },
        { slug: { [Op.like]: `%${search}%` } }
      ];
    }

    // Business context
    const businessId = req.businessContext;
    if (businessId) {
      whereClause.business_id = businessId;
    }

    // Build includes
    const includes = [
      { model: Business, as: 'business' },
      { model: Brand, as: 'brand' },
      { model: Tag, as: 'tags', through: { attributes: [] }, required: false }
    ];

    if (category_id) {
      includes.push({
        model: Category,
        as: 'categories',
        through: { attributes: [] },
        where: { id: parseInt(category_id, 10) },
        required: true
      });
    } else {
      includes.push({ model: Category, as: 'categories', through: { attributes: [] }, required: false });
    }

    const data = await Product.findAndCountAll({
      where: whereClause,
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
      order: [[sortBy, String(sortOrder).toUpperCase()]],
      include: includes
    });

    res.json({
      success: true,
      data: data.rows,
      pagination: {
        page: parseInt(page, 10),
        limit: parseInt(limit, 10),
        total: data.count,
        totalPages: Math.ceil(data.count / limit)
      }
    });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});
router.get('/products/:id', setBusinessContext, setModel(Product, [
  { model: Business, as: 'business' },
  { model: Category, as: 'categories', through: { attributes: [] } },
  { model: Brand, as: 'brand' },
  { model: Tag, as: 'tags', through: { attributes: [] } }
]), crud.get);
// Custom product creation to handle tags and categories
router.post('/products', setBusinessContext, async (req, res) => {
  try {
    const { tag_ids, category_ids, ...productData } = req.body;
    
    // Create the product
    const product = await Product.create(productData);
    
    // Handle tags association
    if (tag_ids && tag_ids.length > 0) {
      await product.setTags(tag_ids);
    }
    
    // Handle categories association (many-to-many)
    if (category_ids && category_ids.length > 0) {
      // Validate that all categories exist and belong to the same business
      const existingCategories = await Category.findAll({
        where: { id: category_ids },
        attributes: ['id', 'business_id', 'name']
      });
      
      const existingCategoryIds = existingCategories.map(cat => cat.id);
      const invalidCategoryIds = category_ids.filter(id => !existingCategoryIds.includes(id));
      
      if (invalidCategoryIds.length > 0) {
        return res.status(400).json({
          success: false,
          error: `Categories not found: ${invalidCategoryIds.join(', ')}`
        });
      }
      
      // Check if all categories belong to the same business
      const businessId = req.businessId || productData.business_id;
      const invalidBusinessCategories = existingCategories.filter(cat => cat.business_id !== businessId);
      
      if (invalidBusinessCategories.length > 0) {
        const invalidNames = invalidBusinessCategories.map(cat => `${cat.name} (ID: ${cat.id})`).join(', ');
        return res.status(400).json({
          success: false,
          error: `Categories must belong to the same business. Invalid categories: ${invalidNames}`
        });
      }
      
      // Set the first category as primary, others as secondary
      const categoryPromises = category_ids.map((categoryId, index) => 
        ProductCategory.create({
          product_id: product.id,
          category_id: categoryId,
          is_primary: index === 0,
          sort_order: index
        })
      );
      await Promise.all(categoryPromises);
    }
    
    // Fetch the created product with associations
    const createdProduct = await Product.findByPk(product.id, {
      include: [
        { model: Tag, as: 'tags', attributes: ['id', 'name', 'color'] },
        { model: Category, as: 'categories', attributes: ['id', 'name', 'slug'], through: { attributes: ['is_primary', 'sort_order'] } },
        { model: Brand, as: 'brand', attributes: ['id', 'name', 'slug'] },
        { model: Business, as: 'business', attributes: ['id', 'business_name', 'business_slug'] }
      ]
    });
    
    res.status(201).json({
      success: true,
      data: createdProduct
    });
  } catch (error) {
    console.error('Error creating product:', error);
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});
// Custom product update to handle tags and categories
router.put('/products/:id', setBusinessContext, async (req, res) => {
  try {
    const { id } = req.params;
    const { tag_ids, category_ids, ...productData } = req.body;
    
    // Find the product
    const product = await Product.findByPk(id);
    if (!product) {
      return res.status(404).json({
        success: false,
        error: 'Product not found'
      });
    }
    
    // Update the product
    await product.update(productData);
    
    // Handle tags association
    if (tag_ids !== undefined) {
      if (tag_ids && tag_ids.length > 0) {
        await product.setTags(tag_ids);
      } else {
        await product.setTags([]);
      }
    }
    
    // Handle categories association (many-to-many)
    if (category_ids !== undefined) {
      // Remove existing category associations
      await ProductCategory.destroy({
        where: { product_id: id }
      });
      
      // Add new category associations
      if (category_ids.length > 0) {
        // Validate that all categories exist and belong to the same business
        const existingCategories = await Category.findAll({
          where: { id: category_ids },
          attributes: ['id', 'business_id', 'name']
        });
        
        const existingCategoryIds = existingCategories.map(cat => cat.id);
        const invalidCategoryIds = category_ids.filter(id => !existingCategoryIds.includes(id));
        
        if (invalidCategoryIds.length > 0) {
          return res.status(400).json({
            success: false,
            error: `Categories not found: ${invalidCategoryIds.join(', ')}`
          });
        }
        
        // Check if all categories belong to the same business
        const businessId = req.businessId || product.business_id;
        const invalidBusinessCategories = existingCategories.filter(cat => cat.business_id !== businessId);
        
        if (invalidBusinessCategories.length > 0) {
          const invalidNames = invalidBusinessCategories.map(cat => `${cat.name} (ID: ${cat.id})`).join(', ');
          return res.status(400).json({
            success: false,
            error: `Categories must belong to the same business. Invalid categories: ${invalidNames}`
          });
        }
        
        const categoryPromises = category_ids.map((categoryId, index) => 
          ProductCategory.create({
            product_id: id,
            category_id: categoryId,
            is_primary: index === 0,
            sort_order: index
          })
        );
        await Promise.all(categoryPromises);
      }
    }
    
    // Fetch the updated product with associations
    const updatedProduct = await Product.findByPk(id, {
      include: [
        { model: Tag, as: 'tags', attributes: ['id', 'name', 'color'] },
        { model: Category, as: 'categories', attributes: ['id', 'name', 'slug'], through: { attributes: ['is_primary', 'sort_order'] } },
        { model: Brand, as: 'brand', attributes: ['id', 'name', 'slug'] },
        { model: Business, as: 'business', attributes: ['id', 'business_name', 'business_slug'] }
      ]
    });
    
    res.json({
      success: true,
      data: updatedProduct
    });
  } catch (error) {
    console.error('Error updating product:', error);
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});
router.delete('/products/:id', setBusinessContext, setModel(Product), crud.delete);
router.post('/products/bulk-delete', setBusinessContext, setModel(Product), crud.bulkDelete);
router.post('/products/bulk-update', setBusinessContext, setModel(Product), crud.bulkUpdate);
router.get('/products/stats/overview', setBusinessContext, setModel(Product), crud.getStats);

// Orders CRUD with business context (Read-only for admin, status updates only)
router.get('/orders', setBusinessContext, setModel(Order, [
  { model: User, as: 'user' },
  { model: Business, as: 'business' },
  { model: OrderItem, as: 'items' }
]), crud.list);
router.get('/orders/:id', setBusinessContext, setModel(Order, [
  { model: User, as: 'user' },
  { model: Business, as: 'business' },
  { model: OrderItem, as: 'items' }
]), crud.get);
router.put('/orders/:id', setBusinessContext, setModel(Order), crud.update);
// Note: Orders cannot be deleted, only cancelled

// Order Items CRUD
router.get('/order-items', setModel(OrderItem, [
  { model: Order, as: 'order' },
  { model: Product, as: 'product' }
]), crud.list);
router.get('/order-items/:id', setModel(OrderItem, [
  { model: Order, as: 'order' },
  { model: Product, as: 'product' }
]), crud.get);
router.put('/order-items/:id', setModel(OrderItem), crud.update);

// Coupons CRUD with business context
router.get('/coupons', setBusinessContext, setModel(Coupon, [{ model: Business, as: 'creator' }]), crud.list);
router.get('/coupons/:id', setBusinessContext, setModel(Coupon, [{ model: Business, as: 'creator' }]), crud.get);
router.post('/coupons', setBusinessContext, setModel(Coupon), crud.create);
router.put('/coupons/:id', setBusinessContext, setModel(Coupon), crud.update);
router.delete('/coupons/:id', setBusinessContext, setModel(Coupon), crud.delete);
router.post('/coupons/bulk-delete', setBusinessContext, setModel(Coupon), crud.bulkDelete);
router.post('/coupons/bulk-update', setBusinessContext, setModel(Coupon), crud.bulkUpdate);

// Reviews CRUD
router.get('/reviews', setBusinessContext, setModel(Review, [
  { model: User, as: 'user' },
  { model: Product, as: 'product' },
  { model: Business, as: 'business' },
  { model: Order, as: 'order' }
]), crud.list);
router.get('/reviews/:id', setBusinessContext, setModel(Review, [
  { model: User, as: 'user' },
  { model: Product, as: 'product' },
  { model: Business, as: 'business' },
  { model: Order, as: 'order' }
]), crud.get);
router.put('/reviews/:id', setBusinessContext, setModel(Review), crud.update);
router.delete('/reviews/:id', setBusinessContext, setModel(Review), crud.delete);
router.post('/reviews/bulk-delete', setBusinessContext, setModel(Review), crud.bulkDelete);
router.post('/reviews/bulk-update', setBusinessContext, setModel(Review), crud.bulkUpdate);

// Carts CRUD (for analytics)
router.get('/carts', setModel(Cart, [
  { model: User, as: 'user' },
  { model: Business, as: 'business' }
]), crud.list);
router.get('/carts/:id', setModel(Cart, [
  { model: User, as: 'user' },
  { model: Business, as: 'business' },
  { model: CartItem, as: 'items' }
]), crud.get);

// Cart Items CRUD
router.get('/cart-items', setModel(CartItem, [
  { model: Cart, as: 'cart' },
  { model: Product, as: 'product' }
]), crud.list);
router.get('/cart-items/:id', setModel(CartItem, [
  { model: Cart, as: 'cart' },
  { model: Product, as: 'product' }
]), crud.get);

// Dashboard Statistics
router.get('/dashboard/stats', setBusinessContext, async (req, res) => {
  try {
    // Build where clauses based on business context
    const businessId = req.businessContext;
    
    const userWhereClause = {};
    const businessWhereClause = businessId ? { id: businessId } : {};
    const productWhereClause = businessId ? { business_id: businessId } : {};
    const orderWhereClause = businessId ? { business_id: businessId } : {};
    
    // For users, if business context is provided, count users who have orders from that business
    if (businessId) {
      const usersWithOrders = await User.findAll({
        attributes: ['id'],
        include: [{
          model: Order,
          as: 'orders',
          where: { business_id: businessId },
          required: true
        }]
      });
      userWhereClause.id = usersWithOrders.map(u => u.id);
    }

    const [
      totalUsers,
      totalBusinesses,
      totalProducts,
      totalOrders,
      totalRevenue,
      activeUsers,
      activeBusinesses,
      activeProducts
    ] = await Promise.all([
      User.count({ where: userWhereClause }),
      Business.count({ where: businessWhereClause }),
      Product.count({ where: productWhereClause }),
      Order.count({ where: orderWhereClause }),
      Order.sum('total_amount', { where: orderWhereClause }),
      User.count({ where: { ...userWhereClause, is_active: true } }),
      Business.count({ where: { ...businessWhereClause, is_active: true } }),
      Product.count({ where: { ...productWhereClause, is_active: true } })
    ]);

    // Recent orders
    const recentOrders = await Order.findAll({
      where: orderWhereClause,
      include: [
        { model: User, as: 'user' },
        { model: Business, as: 'business' }
      ],
      order: [['created_at', 'DESC']],
      limit: 10
    });

    // Top selling products
    const topProducts = await Product.findAll({
      where: productWhereClause,
      order: [['total_sales', 'DESC']],
      limit: 10,
      include: [{ model: Business, as: 'business' }]
    });

    res.json({
      success: true,
      data: {
        overview: {
          totalUsers,
          totalBusinesses,
          totalProducts,
          totalOrders,
          totalRevenue: totalRevenue || 0,
          activeUsers,
          activeBusinesses,
          activeProducts
        },
        recentOrders,
        topProducts
      }
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

// Brands CRUD
router.get('/brands', setModel(Brand), crud.list);
router.get('/brands/:id', setModel(Brand), crud.get);
router.post('/brands', setModel(Brand), crud.create);
router.put('/brands/:id', setModel(Brand), crud.update);
router.delete('/brands/:id', setModel(Brand), crud.delete);
router.post('/brands/bulk-delete', setModel(Brand), crud.bulkDelete);
router.post('/brands/bulk-update', setModel(Brand), crud.bulkUpdate);

// Tags CRUD
router.get('/tags', setModel(Tag), crud.list);
router.get('/tags/:id', setModel(Tag), crud.get);
router.post('/tags', setModel(Tag), crud.create);
router.put('/tags/:id', setModel(Tag), crud.update);
router.delete('/tags/:id', setModel(Tag), crud.delete);
router.post('/tags/bulk-delete', setModel(Tag), crud.bulkDelete);
router.post('/tags/bulk-update', setModel(Tag), crud.bulkUpdate);

// Tag search endpoint for autocomplete
router.get('/tags/search', async (req, res) => {
  try {
    const { q = '', limit = 10 } = req.query;
    
    const tags = await Tag.findAll({
      where: {
        name: {
          [Op.like]: `%${q}%`
        },
        is_active: true
      },
      limit: parseInt(limit),
      order: [['name', 'ASC']]
    });

    res.json({
      success: true,
      data: tags
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

// Create tag if not exists
router.post('/tags/create-if-not-exists', async (req, res) => {
  try {
    const { name, description, color } = req.body;
    
    if (!name) {
      return res.status(400).json({
        success: false,
        error: 'Tag name is required'
      });
    }

    // Check if tag already exists
    let tag = await Tag.findOne({
      where: { name: name.trim() }
    });

    if (!tag) {
      // Create new tag
      tag = await Tag.create({
        name: name.trim(),
        description: description || null,
        color: color || '#007bff'
      });
    }

    res.json({
      success: true,
      data: tag
    });
  } catch (error) {
    res.status(400).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;

