import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext();

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('token');
    if (token) {
      // In a real app, you would validate the token with the server
      setUser({ id: 1, name: 'Admin User', role: 'admin' });
    }
    setLoading(false);
  }, []);

  const login = async (credentials) => {
    try {
      // For demo purposes, accept any email/password combination
      // In production, this would validate against the backend
      if (credentials.email && credentials.password) {
        const mockUser = {
          id: 1,
          name: 'Admin User',
          email: credentials.email,
          role: 'admin'
        };
        
        localStorage.setItem('token', 'demo-token-123');
        setUser(mockUser);
        return { success: true };
      } else {
        return { success: false, error: 'Email and password are required' };
      }
    } catch (error) {
      return { success: false, error: 'Login failed' };
    }
  };

  const logout = () => {
    localStorage.removeItem('token');
    setUser(null);
  };

  const value = {
    user,
    login,
    logout,
    loading
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};
