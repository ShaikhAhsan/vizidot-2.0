const { sequelize } = require('../config/database');

// Import all models
const User = require('./User');
const Role = require('./Role');
const UserRole = require('./UserRole');
const Business = require('./Business');
const BusinessTiming = require('./BusinessTiming');
const Category = require('./Category');
const Product = require('./Product');
const Order = require('./Order');
const OrderItem = require('./OrderItem');
const Coupon = require('./Coupon');
const Review = require('./Review');
const Cart = require('./Cart');
const CartItem = require('./CartItem');
const Brand = require('./Brand');
const Tag = require('./Tag');
const ProductTag = require('./ProductTag');
const ProductCategory = require('./ProductCategory');
const Unit = require('./Unit');

// Define associations
const defineAssociations = () => {
  // User associations
  User.hasMany(Business, { foreignKey: 'user_id', as: 'businesses' });
  User.hasMany(Order, { foreignKey: 'user_id', as: 'orders' });
  User.hasMany(Review, { foreignKey: 'user_id', as: 'reviews' });
  User.hasMany(Cart, { foreignKey: 'user_id', as: 'carts' });
  
  // RBAC associations
  User.belongsToMany(Role, { 
    through: UserRole, 
    foreignKey: 'user_id', 
    otherKey: 'role_id',
    as: 'roles'
  });
  Role.belongsToMany(User, { 
    through: UserRole, 
    foreignKey: 'role_id', 
    otherKey: 'user_id',
    as: 'users'
  });
  UserRole.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
  UserRole.belongsTo(Role, { foreignKey: 'role_id', as: 'role' });
  UserRole.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });

  // Business associations
  Business.belongsTo(User, { foreignKey: 'user_id', as: 'owner' });
  Business.hasMany(BusinessTiming, { foreignKey: 'business_id', as: 'timings' });
  Business.hasMany(Category, { foreignKey: 'business_id', as: 'categories' });
  Business.hasMany(Product, { foreignKey: 'business_id', as: 'products' });
  Business.hasMany(Order, { foreignKey: 'business_id', as: 'orders' });
  Business.hasMany(Coupon, { foreignKey: 'creator_id', as: 'coupons' });
  Business.hasMany(Review, { foreignKey: 'business_id', as: 'reviews' });

  // BusinessTiming associations
  BusinessTiming.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });

  // Category associations
  Category.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
  Category.belongsToMany(Product, { 
    through: ProductCategory, 
    foreignKey: 'category_id', 
    otherKey: 'product_id',
    as: 'products'
  });

  // Product associations
  Product.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
  Product.belongsTo(Brand, { foreignKey: 'brand_id', as: 'brand' });
  Product.belongsToMany(Category, { 
    through: ProductCategory, 
    foreignKey: 'product_id', 
    otherKey: 'category_id',
    as: 'categories'
  });
  Product.belongsToMany(Tag, { 
    through: ProductTag, 
    foreignKey: 'product_id', 
    otherKey: 'tag_id',
    as: 'tags'
  });
  Product.hasMany(OrderItem, { foreignKey: 'product_id', as: 'orderItems' });
  Product.hasMany(Review, { foreignKey: 'product_id', as: 'reviews' });
  Product.hasMany(CartItem, { foreignKey: 'product_id', as: 'cartItems' });

  // Order associations
  Order.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
  Order.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
  Order.hasMany(OrderItem, { foreignKey: 'order_id', as: 'items' });
  Order.hasMany(Review, { foreignKey: 'order_id', as: 'reviews' });

  // OrderItem associations
  OrderItem.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });
  OrderItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

  // Coupon associations
  Coupon.belongsTo(Business, { foreignKey: 'creator_id', as: 'creator' });

  // Review associations
  Review.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
  Review.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
  Review.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
  Review.belongsTo(Order, { foreignKey: 'order_id', as: 'order' });

  // Cart associations
  Cart.belongsTo(User, { foreignKey: 'user_id', as: 'user' });
  Cart.belongsTo(Business, { foreignKey: 'business_id', as: 'business' });
  Cart.hasMany(CartItem, { foreignKey: 'cart_id', as: 'items' });

  // CartItem associations
  CartItem.belongsTo(Cart, { foreignKey: 'cart_id', as: 'cart' });
  CartItem.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });

  // Brand associations
  Brand.hasMany(Product, { foreignKey: 'brand_id', as: 'products' });

  // Tag associations
  Tag.belongsToMany(Product, { 
    through: ProductTag, 
    foreignKey: 'tag_id', 
    otherKey: 'product_id',
    as: 'products'
  });

  // ProductTag associations
  ProductTag.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
  ProductTag.belongsTo(Tag, { foreignKey: 'tag_id', as: 'tag' });

  // ProductCategory associations
  ProductCategory.belongsTo(Product, { foreignKey: 'product_id', as: 'product' });
  ProductCategory.belongsTo(Category, { foreignKey: 'category_id', as: 'category' });
};

// Initialize associations
defineAssociations();

// Export all models and sequelize instance
module.exports = {
  sequelize,
  User,
  Role,
  UserRole,
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
  ProductCategory,
  Unit
};

