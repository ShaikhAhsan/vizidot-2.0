import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from 'antd';
import Sidebar from './components/Layout/Sidebar';
import Header from './components/Layout/Header';
import { FirebaseAuthProvider } from './contexts/FirebaseAuthContext';
import { ArtistProvider } from './contexts/ArtistContext';
import ProtectedRoute from './components/Auth/ProtectedRoute';
import LoginPage from './pages/LoginPage';
import './App.css';
import ArtistsPage from './pages/ArtistsPage';
import ArtistFormPage from './pages/ArtistFormPage';
import AlbumsPage from './pages/AlbumsPage';
import AlbumFormPage from './pages/AlbumFormPage';
import AlbumTracksPage from './pages/AlbumTracksPage';
import BrandingsPage from './pages/BrandingsPage';
import BrandingFormPage from './pages/BrandingFormPage';
import ShopsPage from './pages/ShopsPage';
import ShopFormPage from './pages/ShopFormPage';

const { Content } = Layout;

function App() {
  return (
    <FirebaseAuthProvider>
      <ArtistProvider>
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
                          <Route path="/" element={<Navigate to="/artists" replace />} />
                          {/* Music Platform Routes */}
                          <Route path="/artists" element={<ArtistsPage />} />
                          <Route path="/artists/create" element={<ArtistFormPage />} />
                          <Route path="/artists/edit/:id" element={<ArtistFormPage />} />
                          <Route path="/albums" element={<AlbumsPage />} />
                          <Route path="/albums/create" element={<AlbumFormPage />} />
                          <Route path="/albums/edit/:id" element={<AlbumFormPage />} />
                          <Route path="/albums/:id/tracks" element={<AlbumTracksPage />} />
                          <Route path="/brandings" element={<BrandingsPage />} />
                          <Route path="/brandings/create" element={<BrandingFormPage />} />
                          <Route path="/brandings/edit/:id" element={<BrandingFormPage />} />
                          <Route path="/shops" element={<ShopsPage />} />
                          <Route path="/shops/create" element={<ShopFormPage />} />
                          <Route path="/shops/edit/:id" element={<ShopFormPage />} />
                        </Routes>
                      </Content>
                    </Layout>
                  </Layout>
                </ProtectedRoute>
              }
            />
          </Routes>
        </div>
      </ArtistProvider>
    </FirebaseAuthProvider>
  );
}

export default App;
