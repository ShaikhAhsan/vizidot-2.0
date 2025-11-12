import React, { createContext, useContext, useState, useEffect } from 'react';
import { initializeApp } from 'firebase/app';
import { getAnalytics } from 'firebase/analytics';
import { 
  getAuth, 
  signInWithEmailAndPassword, 
  signOut,
  onAuthStateChanged,
  GoogleAuthProvider,
  signInWithPopup
} from 'firebase/auth';
import { message } from 'antd';

// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyAxoexhg5tGF9ee_7BUHxZrirZgcpvlQGQ",
  authDomain: "vizidot-4b492.firebaseapp.com",
  projectId: "vizidot-4b492",
  storageBucket: "vizidot-4b492.appspot.com",
  messagingSenderId: "538542923941",
  appId: "1:538542923941:web:3bbf4ff31b1eeb70caad4c",
  measurementId: "G-JR37CPBNR2"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const analytics = getAnalytics(app);
const auth = getAuth(app);
const googleProvider = new GoogleAuthProvider();

const FirebaseAuthContext = createContext();

export const useFirebaseAuth = () => {
  const context = useContext(FirebaseAuthContext);
  if (!context) {
    throw new Error('useFirebaseAuth must be used within a FirebaseAuthProvider');
  }
  return context;
};

export const FirebaseAuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [userProfile, setUserProfile] = useState(null);

  // Listen for authentication state changes
  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        setUser(firebaseUser);
        
        // Get user profile from backend by calling login endpoint
        try {
          const idToken = await firebaseUser.getIdToken();
          const response = await fetch('/api/v1/auth/login', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ idToken })
          });
          
          if (response.ok) {
            const data = await response.json();
            setUserProfile(data.data.user);
          } else {
            console.error('Failed to get user profile on auth state change');
            // If user profile fetch fails, sign out
            await signOut(auth);
          }
        } catch (error) {
          console.error('Error fetching user profile:', error);
          // If there's an error, sign out to prevent stuck state
          await signOut(auth);
        }
      } else {
        setUser(null);
        setUserProfile(null);
      }
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  // Sign in with email and password
  const signIn = async (email, password) => {
    try {
      setLoading(true);
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const idToken = await userCredential.user.getIdToken();
      
      // Update user profile in backend
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ idToken })
      });
      
      if (response.ok) {
        const data = await response.json();
        setUserProfile(data.data.user);
        message.success('Login successful!');
        return { success: true, user: data.data.user };
      } else {
        const error = await response.json();
        // If login fails due to insufficient privileges, sign out the user
        if (error.error && error.error.includes('privileges')) {
          await signOut(auth);
        }
        throw new Error(error.error || 'Login failed');
      }
    } catch (error) {
      console.error('Sign in error:', error);
      message.error(error.message || 'Login failed');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Sign up with email and password
  const signUp = async (userData) => {
    try {
      setLoading(true);
      const { email, password, firstName, lastName, phone, countryCode, userType, role } = userData;
      
      // Create user in Firebase and backend
      const response = await fetch('/api/v1/auth/register', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          email,
          password,
          firstName,
          lastName,
          phone,
          countryCode,
          userType,
          role
        })
      });
      
      if (response.ok) {
        const data = await response.json();
        message.success('Registration successful!');
        return { success: true, user: data.data.user };
      } else {
        const error = await response.json();
        throw new Error(error.error || 'Registration failed');
      }
    } catch (error) {
      console.error('Sign up error:', error);
      message.error(error.message || 'Registration failed');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Sign in with Google
  const signInWithGoogle = async () => {
    try {
      setLoading(true);
      const result = await signInWithPopup(auth, googleProvider);
      const idToken = await result.user.getIdToken();
      
      // Update user profile in backend
      const response = await fetch('/api/v1/auth/login', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ idToken })
      });
      
      if (response.ok) {
        const data = await response.json();
        setUserProfile(data.data.user);
        message.success('Google login successful!');
        return { success: true, user: data.data.user };
      } else {
        const error = await response.json();
        // If login fails due to insufficient privileges, sign out the user
        if (error.error && error.error.includes('privileges')) {
          await signOut(auth);
        }
        throw new Error(error.error || 'Google login failed');
      }
    } catch (error) {
      console.error('Google sign in error:', error);
      message.error(error.message || 'Google login failed');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Sign out
  const signOutUser = async () => {
    try {
      setLoading(true);
      
      // Sign out from backend
      if (user) {
        const idToken = await user.getIdToken();
        await fetch('/api/v1/auth/logout', {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${idToken}`,
            'Content-Type': 'application/json'
          }
        });
      }
      
      // Sign out from Firebase
      await signOut(auth);
      setUser(null);
      setUserProfile(null);
      message.success('Logged out successfully!');
    } catch (error) {
      console.error('Sign out error:', error);
      message.error('Logout failed');
    } finally {
      setLoading(false);
    }
  };

  // Send password reset email
  const resetPassword = async (email) => {
    try {
      setLoading(true);
      
      const response = await fetch('/api/v1/auth/forgot-password', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ email })
      });
      
      if (response.ok) {
        const data = await response.json();
        message.success('Password reset link sent to your email!');
        return { success: true, resetLink: data.data.resetLink };
      } else {
        const error = await response.json();
        throw new Error(error.error || 'Failed to send password reset email');
      }
    } catch (error) {
      console.error('Password reset error:', error);
      message.error(error.message || 'Failed to send password reset email');
      return { success: false, error: error.message };
    } finally {
      setLoading(false);
    }
  };

  // Update user profile
  const updateProfile = async (profileData) => {
    try {
      if (!user) throw new Error('User not authenticated');
      
      const idToken = await user.getIdToken();
      const response = await fetch('/api/v1/auth/me', {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${idToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(profileData)
      });
      
      if (response.ok) {
        const data = await response.json();
        setUserProfile(data.data.user);
        message.success('Profile updated successfully!');
        return { success: true, user: data.data.user };
      } else {
        const error = await response.json();
        throw new Error(error.error || 'Failed to update profile');
      }
    } catch (error) {
      console.error('Update profile error:', error);
      message.error(error.message || 'Failed to update profile');
      return { success: false, error: error.message };
    }
  };

  // Check if user has specific role
  const hasRole = (role) => {
    if (!userProfile) return false;
    
    // Check primary role
    if (userProfile.role === role) {
      return true;
    }
    
    // Check roles array if available
    if (userProfile.roles && Array.isArray(userProfile.roles)) {
      return userProfile.roles.some(userRole => 
        (userRole.role?.name || userRole.name) === role
      );
    }
    
    return false;
  };

  // Check if user has any of the specified roles
  const hasAnyRole = (roles) => {
    if (!userProfile) return false;
    
    // Check primary role
    if (userProfile.role && roles.includes(userProfile.role)) {
      return true;
    }
    
    // Check roles array if available
    if (userProfile.roles && Array.isArray(userProfile.roles)) {
      return userProfile.roles.some(userRole => 
        roles.includes(userRole.role?.name || userRole.name)
      );
    }
    
    return false;
  };

  // Check if user is admin
  const isAdmin = () => {
    return hasAnyRole(['super_admin', 'admin']);
  };

  // Check if user is super admin
  const isSuperAdmin = () => {
    return hasRole('super_admin');
  };

  // Check if user is business admin
  const isBusinessAdmin = () => {
    return hasAnyRole(['super_admin', 'admin', 'business_admin']);
  };

  const value = {
    user,
    userProfile,
    loading,
    signIn,
    signUp,
    signInWithGoogle,
    signOut: signOutUser,
    resetPassword,
    updateProfile,
    hasRole,
    hasAnyRole,
    isAdmin,
    isSuperAdmin,
    isBusinessAdmin
  };

  return (
    <FirebaseAuthContext.Provider value={value}>
      {children}
    </FirebaseAuthContext.Provider>
  );
};

export default FirebaseAuthContext;
