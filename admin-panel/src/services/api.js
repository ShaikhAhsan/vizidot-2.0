import { getAuth } from 'firebase/auth';

// Get Firebase auth instance
const auth = getAuth();

// API base URL
const API_BASE_URL = '';

// Helper function to get the current user's ID token
const getIdToken = async () => {
  const user = auth.currentUser;
  if (!user) {
    throw new Error('No authenticated user');
  }
  return await user.getIdToken();
};

// API request helper with automatic token inclusion and business context
const apiRequest = async (endpoint, options = {}) => {
  try {
    const token = await getIdToken();
    
    // Get business context headers if available
    const businessContextHeaders = window.getBusinessContextHeaders?.() || {};
    
    const config = {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
        ...businessContextHeaders,
        ...options.headers
      },
      ...options
    };

    const response = await fetch(`${API_BASE_URL}${endpoint}`, config);
    
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ error: 'Request failed' }));
      throw new Error(errorData.error || `HTTP ${response.status}`);
    }
    
    return await response.json();
  } catch (error) {
    console.error('API request failed:', error);
    throw error;
  }
};

// API service methods
export const apiService = {
  // GET request
  get: (endpoint) => apiRequest(endpoint, { method: 'GET' }),
  
  // POST request
  post: (endpoint, data) => apiRequest(endpoint, {
    method: 'POST',
    body: JSON.stringify(data)
  }),
  
  // PUT request
  put: (endpoint, data) => apiRequest(endpoint, {
    method: 'PUT',
    body: JSON.stringify(data)
  }),
  
  // DELETE request
  delete: (endpoint) => apiRequest(endpoint, { method: 'DELETE' }),
  
  // PATCH request
  patch: (endpoint, data) => apiRequest(endpoint, {
    method: 'PATCH',
    body: JSON.stringify(data)
  })
};

// Specific API endpoints
export const adminAPI = {
  // Dashboard
  getDashboardStats: () => apiService.get('/api/v1/admin/dashboard/stats'),
  
  // Users
  getUsers: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/users?page=${page}&limit=${limit}`),
  createUser: (userData) => apiService.post('/api/v1/admin/users', userData),
  updateUser: (id, userData) => apiService.put(`/api/v1/admin/users/${id}`, userData),
  deleteUser: (id) => apiService.delete(`/api/v1/admin/users/${id}`),
  getUser: (id) => apiService.get(`/api/v1/admin/users/${id}`),
  
  // Businesses
  getBusinesses: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/businesses?page=${page}&limit=${limit}`),
  createBusiness: (businessData) => apiService.post('/api/v1/admin/businesses', businessData),
  updateBusiness: (id, businessData) => apiService.put(`/api/v1/admin/businesses/${id}`, businessData),
  deleteBusiness: (id) => apiService.delete(`/api/v1/admin/businesses/${id}`),
  getBusiness: (id) => apiService.get(`/api/v1/admin/businesses/${id}`),
  
  // Products
  getProducts: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/products?page=${page}&limit=${limit}`),
  createProduct: (productData) => apiService.post('/api/v1/admin/products', productData),
  updateProduct: (id, productData) => apiService.put(`/api/v1/admin/products/${id}`, productData),
  deleteProduct: (id) => apiService.delete(`/api/v1/admin/products/${id}`),
  getProduct: (id) => apiService.get(`/api/v1/admin/products/${id}`),
  
  // Orders
  getOrders: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/orders?page=${page}&limit=${limit}`),
  updateOrder: (id, orderData) => apiService.put(`/api/v1/admin/orders/${id}`, orderData),
  deleteOrder: (id) => apiService.delete(`/api/v1/admin/orders/${id}`),
  getOrder: (id) => apiService.get(`/api/v1/admin/orders/${id}`),
  
  // Categories
  getCategories: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/categories?page=${page}&limit=${limit}`),
  createCategory: (categoryData) => apiService.post('/api/v1/admin/categories', categoryData),
  updateCategory: (id, categoryData) => apiService.put(`/api/v1/admin/categories/${id}`, categoryData),
  deleteCategory: (id) => apiService.delete(`/api/v1/admin/categories/${id}`),
  getCategory: (id) => apiService.get(`/api/v1/admin/categories/${id}`),
  
  // Coupons
  getCoupons: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/coupons?page=${page}&limit=${limit}`),
  createCoupon: (couponData) => apiService.post('/api/v1/admin/coupons', couponData),
  updateCoupon: (id, couponData) => apiService.put(`/api/v1/admin/coupons/${id}`, couponData),
  deleteCoupon: (id) => apiService.delete(`/api/v1/admin/coupons/${id}`),
  getCoupon: (id) => apiService.get(`/api/v1/admin/coupons/${id}`),
  
  // Reviews
  getReviews: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/reviews?page=${page}&limit=${limit}`),
  updateReview: (id, reviewData) => apiService.put(`/api/v1/admin/reviews/${id}`, reviewData),
  deleteReview: (id) => apiService.delete(`/api/v1/admin/reviews/${id}`),
  getReview: (id) => apiService.get(`/api/v1/admin/reviews/${id}`),
  
  // Brands
  getBrands: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/brands?page=${page}&limit=${limit}`),
  createBrand: (brandData) => apiService.post('/api/v1/admin/brands', brandData),
  updateBrand: (id, brandData) => apiService.put(`/api/v1/admin/brands/${id}`, brandData),
  deleteBrand: (id) => apiService.delete(`/api/v1/admin/brands/${id}`),
  getBrand: (id) => apiService.get(`/api/v1/admin/brands/${id}`),
  
  // Test endpoint for development
  getTestData: () => apiService.get('/api/v1/admin/test'),
  
  // Tags
  getTags: (page = 1, limit = 10) => apiService.get(`/api/v1/admin/tags?page=${page}&limit=${limit}`),
  createTag: (tagData) => apiService.post('/api/v1/admin/tags', tagData),
  updateTag: (id, tagData) => apiService.put(`/api/v1/admin/tags/${id}`, tagData),
  deleteTag: (id) => apiService.delete(`/api/v1/admin/tags/${id}`),
  getTag: (id) => apiService.get(`/api/v1/admin/tags/${id}`),
  searchTags: (query = '', limit = 10) => apiService.get(`/api/v1/admin/tags/search?q=${query}&limit=${limit}`),
  createTagIfNotExists: (tagData) => apiService.post('/api/v1/admin/tags/create-if-not-exists', tagData)
};

export default apiService;
