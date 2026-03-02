import React from 'react';
import { Navigate } from 'react-router-dom';
import { useFirebaseAuth } from '../../contexts/FirebaseAuthContext';
import { Spin } from 'antd';

const ProtectedRoute = ({ children, requireAdmin = true }) => {
  const { user, userProfile, loading, isAdmin } = useFirebaseAuth();

  if (loading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <Spin size="large" />
      </div>
    );
  }

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // If userProfile is not loaded yet, show loading
  if (!userProfile) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <Spin size="large" />
      </div>
    );
  }

  // Check admin access if required - allow users with assigned artists
  if (requireAdmin) {
    const hasAdminRole = isAdmin();
    const hasAssignedArtists = userProfile?.assignedArtists && userProfile.assignedArtists.length > 0;
    
    if (!hasAdminRole && !hasAssignedArtists) {
      return <Navigate to="/login" replace />;
    }
  }

  return children;
};

export default ProtectedRoute;
