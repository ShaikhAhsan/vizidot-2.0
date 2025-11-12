import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from 'antd';
import Sidebar from './components/Layout/Sidebar';
import Header from './components/Layout/Header';
import Dashboard from './pages/Dashboard';
import UsersPage from './pages/UsersPage';
import BusinessesPage from './pages/BusinessesPage';
import ProductsPage from './pages/ProductsPage';
import OrdersPage from './pages/OrdersPage';
import CategoriesPage from './pages/CategoriesPage';
import BrandsPage from './pages/BrandsPage';
import TagsPage from './pages/TagsPage';
import CouponsPage from './pages/CouponsPage';
import ReviewsPage from './pages/ReviewsPage';
import { FirebaseAuthProvider } from './contexts/FirebaseAuthContext';
import { BusinessProvider } from './contexts/BusinessContext';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import LoginPage from './pages/LoginPage';
import './App.css';
import CategoryProductsPage from './pages/CategoryProductsPage';

const { Content } = Layout;

function App() {
  return (
    <FirebaseAuthProvider>
      <BusinessProvider>
        <div className="App">
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route
              path="/*"
              element={
                <ProtectedRoute>
                  <Layout style={{ minHeight: '100vh' }}>
                    <Sidebar />
                    <Layout>
                      <Header />
                      <Content>
                        <Routes>
                          <Route path="/" element={<Navigate to="/dashboard" replace />} />
                          <Route path="/dashboard" element={<Dashboard />} />
                          <Route path="/users" element={<UsersPage />} />
                          <Route path="/businesses" element={<BusinessesPage />} />
                          <Route path="/products" element={<ProductsPage />} />
                          <Route path="/orders" element={<OrdersPage />} />
                          <Route path="/categories" element={<CategoriesPage />} />
                          <Route path="/categories/:id/products" element={<CategoryProductsPage />} />
                          <Route path="/brands" element={<BrandsPage />} />
                          <Route path="/tags" element={<TagsPage />} />
                          <Route path="/coupons" element={<CouponsPage />} />
                          <Route path="/reviews" element={<ReviewsPage />} />
                        </Routes>
                      </Content>
                    </Layout>
                  </Layout>
                </ProtectedRoute>
              }
            />
          </Routes>
        </div>
      </BusinessProvider>
    </FirebaseAuthProvider>
  );
}

export default App;
