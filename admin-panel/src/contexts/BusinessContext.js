import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useFirebaseAuth } from './FirebaseAuthContext';
import { adminAPI } from '../services/api';

const BusinessContext = createContext();

export const useBusinessContext = () => {
  const context = useContext(BusinessContext);
  if (!context) {
    throw new Error('useBusinessContext must be used within a BusinessProvider');
  }
  return context;
};

// Alias for backward compatibility
export const useBusiness = useBusinessContext;

export const BusinessProvider = ({ children }) => {
  const [businesses, setBusinesses] = useState([]);
  const [selectedBusiness, setSelectedBusiness] = useState(null);
  const [loading, setLoading] = useState(false);
  const { userProfile, highestRole } = useFirebaseAuth();

  // Check if user is super admin
  const isSuperAdmin = userProfile?.role === 'super_admin' || highestRole?.name === 'super_admin';
  

  // Fetch businesses for super admin
  const fetchBusinesses = async () => {
    if (!isSuperAdmin) return;
    
    setLoading(true);
    try {
      const response = await adminAPI.getBusinesses();
      if (response.success) {
        // Add "All Businesses" option at the beginning
        const allBusinessesOption = {
          id: 'all',
          business_name: 'All Businesses',
          business_type: 'All',
          is_active: true
        };
        setBusinesses([allBusinessesOption, ...response.data]);
        
        // Set "All Businesses" as default if none selected
        if (!selectedBusiness) {
          setSelectedBusiness(allBusinessesOption);
        }
      }
    } catch (error) {
      console.error('Failed to fetch businesses:', error);
    } finally {
      setLoading(false);
    }
  };

  // Switch business context
  const switchBusiness = (business) => {
    setSelectedBusiness(business);
    // Store in localStorage for persistence
    localStorage.setItem('selectedBusiness', JSON.stringify(business));
  };

  // Get current business context for API calls
  const getBusinessContext = useCallback(() => {
    if (isSuperAdmin && selectedBusiness) {
      // If "All Businesses" is selected, return null to show all data
      return selectedBusiness.id === 'all' ? null : selectedBusiness.id;
    }
    return null;
  }, [isSuperAdmin, selectedBusiness]);

  // Get business context header for API calls
  const getBusinessContextHeader = useCallback(() => {
    const businessId = getBusinessContext();
    return businessId ? { 'x-business-id': businessId } : {};
  }, [isSuperAdmin, selectedBusiness]);

  // Expose business context headers globally for API service
  React.useEffect(() => {
    window.getBusinessContextHeaders = getBusinessContextHeader;
    return () => {
      delete window.getBusinessContextHeaders;
    };
  }, [selectedBusiness, getBusinessContextHeader]);

  // Load selected business from localStorage on mount
  useEffect(() => {
    const savedBusiness = localStorage.getItem('selectedBusiness');
    if (savedBusiness) {
      try {
        setSelectedBusiness(JSON.parse(savedBusiness));
      } catch (error) {
        console.error('Failed to parse saved business:', error);
        localStorage.removeItem('selectedBusiness');
      }
    }
  }, []);

  // Fetch businesses when user becomes super admin
  useEffect(() => {
    if (isSuperAdmin && userProfile) {
      // Avoid duplicate fetches in StrictMode by checking existing list
      if (!businesses || businesses.length === 0) {
        fetchBusinesses();
      }
    }
  }, [isSuperAdmin, userProfile]);

  const value = {
    businesses,
    selectedBusiness,
    loading,
    isSuperAdmin,
    switchBusiness,
    getBusinessContext,
    getBusinessContextHeader,
    fetchBusinesses
  };

  return (
    <BusinessContext.Provider value={value}>
      {children}
    </BusinessContext.Provider>
  );
};
