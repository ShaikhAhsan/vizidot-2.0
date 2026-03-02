// Mock data service for ProductForm when API is not available
export const mockData = {
  brands: [
    { id: 1, name: 'Nestle', description: 'Swiss multinational food and drink processing conglomerate' },
    { id: 2, name: 'Unilever', description: 'British-Dutch multinational consumer goods company' },
    { id: 3, name: 'P&G', description: 'American multinational consumer goods corporation' },
    { id: 4, name: 'Colgate', description: 'American multinational consumer products company' },
    { id: 5, name: 'Dove', description: 'Personal care brand owned by Unilever' }
  ],
  
  categories: [
    // Empty - should load from API based on business context
  ],
  
  // Business-specific categories for fallback
  businessCategories: {
    1: [
      { id: 11, name: 'Electronics', description: 'Electronic devices and gadgets' },
      { id: 12, name: 'Clothing', description: 'Apparel and fashion items' },
      { id: 13, name: 'Sports', description: 'Sports equipment and accessories' }
    ],
    2: [
      { id: 1, name: 'Rice & Grains', description: 'Basmati rice, wheat flour, and other grains' }
    ],
    8: [
      { id: 3, name: 'Dairy Products', description: 'Milk, yogurt, cheese, and dairy items' },
      { id: 8, name: 'Beverages', description: 'Drinks and beverages' }
    ],
    9: [
      { id: 5, name: 'Vegetables', description: 'Fresh seasonal vegetables' },
      { id: 7, name: 'Bakery Items', description: 'Bread, naan, and baked goods' },
      { id: 10, name: 'Household Items', description: 'Household and cleaning products' }
    ],
    10: [
      { id: 4, name: 'Meat & Poultry', description: 'Fresh meat, chicken, and poultry products' }
    ]
  },
  
  tags: [
    { id: 1, name: 'Organic', description: 'Products made with organic ingredients', color: '#28a745' },
    { id: 2, name: 'Gluten Free', description: 'Products that do not contain gluten', color: '#17a2b8' },
    { id: 3, name: 'Dairy Free', description: 'Products that do not contain dairy', color: '#ffc107' },
    { id: 4, name: 'Vegan', description: 'Products suitable for vegans', color: '#6f42c1' },
    { id: 5, name: 'Low Sugar', description: 'Products with reduced sugar content', color: '#fd7e14' }
  ]
};

export default mockData;
