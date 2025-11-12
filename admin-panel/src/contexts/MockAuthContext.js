import React, { createContext, useContext, useState, useEffect } from 'react';
import { message } from 'antd';

const MockAuthContext = createContext();

export const useMockAuth = () => {
  const context = useContext(MockAuthContext);
  if (!context) {
    throw new Error('useMockAuth must be used within a MockAuthProvider');
  }
  return context;
};

export const MockAuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [userProfile, setUserProfile] = useState(null);
  const [loading, setLoading] = useState(false);

  // Mock user data
  const mockUser = {
    id: 'mock-user-1',
    email: 'admin@ebazar.com',
    first_name: 'Admin',
    last_name: 'User',
    phone: '1234567890',
    country_code: '+92',
    user_type: 'admin',
    role: 'super_admin',
    is_verified: true,
    is_active: true
  };

  // Mock sign in
  const signIn = async (email, password) => {
    setLoading(true);
    try {
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Mock authentication - accept any email/password for testing
      if (email && password) {
        setUser({ uid: 'mock-firebase-uid' });
        setUserProfile(mockUser);
        message.success('Login successful! (Mock Mode)');
        return { success: true, user: mockUser };
      } else {
        throw new Error('Email and password are required');
      }
    } catch (error) {
      message.error(error.message || 'Login failed');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Mock Google sign in
  const signInWithGoogle = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      setUser({ uid: 'mock-google-uid' });
      setUserProfile(mockUser);
      message.success('Google login successful! (Mock Mode)');
      return { success: true, user: mockUser };
    } catch (error) {
      message.error('Google login failed');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Mock sign out
  const signOut = async () => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      setUser(null);
      setUserProfile(null);
      message.success('Logged out successfully!');
    } catch (error) {
      message.error('Logout failed');
    } finally {
      setLoading(false);
    }
  };

  // Mock password reset
  const resetPassword = async (email) => {
    setLoading(true);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      message.success(`Password reset link sent to ${email}! (Mock Mode)`);
      return { success: true };
    } catch (error) {
      message.error('Failed to send password reset email');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Mock profile update
  const updateProfile = async (profileData) => {
    try {
      await new Promise(resolve => setTimeout(resolve, 500));
      const updatedProfile = { ...userProfile, ...profileData };
      setUserProfile(updatedProfile);
      message.success('Profile updated successfully! (Mock Mode)');
      return { success: true, user: updatedProfile };
    } catch (error) {
      message.error('Failed to update profile');
      return { success: false, error: error.message };
    }
  };

  // Role checking functions
  const hasRole = (role) => {
    if (!userProfile) return false;
    return userProfile.role === role;
  };

  const hasAnyRole = (roles) => {
    if (!userProfile) return false;
    return roles.includes(userProfile.role);
  };

  const isAdmin = () => {
    return hasAnyRole(['super_admin', 'admin']);
  };

  const isSuperAdmin = () => {
    return hasRole('super_admin');
  };

  const isBusinessAdmin = () => {
    return hasAnyRole(['super_admin', 'admin', 'business_admin']);
  };

  const value = {
    user,
    userProfile,
    loading,
    signIn,
    signInWithGoogle,
    signOut,
    resetPassword,
    updateProfile,
    hasRole,
    hasAnyRole,
    isAdmin,
    isSuperAdmin,
    isBusinessAdmin
  };

  return (
    <MockAuthContext.Provider value={value}>
      {children}
    </MockAuthContext.Provider>
  );
};

export default MockAuthContext;
