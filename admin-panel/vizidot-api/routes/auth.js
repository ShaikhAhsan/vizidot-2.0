const express = require('express');
const router = express.Router();
const FirebaseAuthService = require('../services/firebaseAuth');
const { authenticateToken, requireSystemAdmin } = require('../middleware/authWithRoles');
const { User } = require('../models');

/**
 * @route POST /api/v1/auth/register
 * @desc Register a new user
 * @access Public
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, firstName, lastName, phone, countryCode, role } = req.body;

    // Validate required fields
    if (!email || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        error: 'Email, password, first name, and last name are required'
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ where: { email } });
    if (existingUser) {
      return res.status(409).json({
        success: false,
        error: 'User with this email already exists'
      });
    }

    // Create user in Firebase and MySQL
    const result = await FirebaseAuthService.createUser({
      email,
      password,
      firstName,
      lastName,
      phone,
      countryCode: countryCode || '+92',
      role: role || 'customer'
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      data: {
        user: result.mysqlUser,
        firebaseUid: result.firebaseUser.uid
      }
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Registration failed'
    });
  }
});

/**
 * @route POST /api/v1/auth/login
 * @desc Login user (Firebase handles authentication)
 * @access Public
 */
router.post('/login', async (req, res) => {
  try {
    const { idToken } = req.body;
    const startTs = Date.now();
    const log = (stage, extra = {}) => {
      try {
        const safe = {
          stage,
          ts: new Date().toISOString(),
          latencyMs: Date.now() - startTs,
          providerHint: typeof idToken === 'string' ? (idToken.includes('eyJ') ? 'jwt' : 'unknown') : 'missing',
          ...extra
        };
        console.log('[AUTH_LOGIN]', JSON.stringify(safe));
      } catch (_) {
        // noop
      }
    };
    log('request_received');

    if (!idToken) {
      log('missing_token');
      return res.status(400).json({
        success: false,
        error: 'ID token is required'
      });
    }

    // Development bypass: allow demo token to log in as demo admin
    if (process.env.NODE_ENV === 'development' && idToken === 'demo-token-123') {
      let user = await User.findOne({ where: { email: 'admin@demo.com' } });
      if (!user) {
        user = await User.create({
          email: 'admin@demo.com',
          first_name: 'Demo',
          last_name: 'Admin',
          firebase_uid: 'demo-admin-uid',
          primary_role: 'admin',
          is_active: true,
          is_verified: true
        });
      }

      const RBACService = require('../services/rbacService');
      const userRoles = await RBACService.getUserRoles(user.id);
      const highestRole = await RBACService.getUserHighestRole(user.id);
      const userBusinesses = await RBACService.getUserBusinesses(user.id);

      const userData = user.toJSON();
      userData.roles = userRoles;
      userData.highestRole = highestRole;
      userData.userBusinesses = userBusinesses;
      userData.role = highestRole?.name || userData.primary_role;

      log('demo_login_success', { userId: user.id });
      return res.json({
        success: true,
        message: 'Login successful (demo)',
        data: { user: userData, token: idToken }
      });
    }

    // Verify token and get user (Firebase)
    let user;
    try {
      log('token_verification_start');
      user = await FirebaseAuthService.getUserFromToken(idToken);
      log('token_verification_success', { userId: user?.id, email: user?.email });
    } catch (e) {
      log('token_verification_failed', { error: e?.message });
      return res.status(401).json({ success: false, error: e.message || 'Invalid or expired token' });
    }
    
    // Update last login
    await User.update(
      { last_login: new Date() },
      { where: { id: user.id } }
    );

    // Get user roles for RBAC
    const RBACService = require('../services/rbacService');
    let userRoles = [];
    let highestRole = null;
    let userBusinesses = [];
    
    try {
      userRoles = await RBACService.getUserRoles(user.id);
      highestRole = await RBACService.getUserHighestRole(user.id);
      userBusinesses = await RBACService.getUserBusinesses(user.id);
      log('rbac_fetched', { rolesCount: userRoles?.length || 0, highestRole: highestRole?.name, businesses: userBusinesses?.length || 0 });
    } catch (rbacError) {
      console.error('RBAC fetch error (non-fatal):', rbacError);
      log('rbac_fetch_failed', { error: rbacError?.message });
      // Continue with empty roles - user can still login
    }

    // Get assigned artists
    const { Artist, UserArtist } = require('../models');
    let assignedArtists = [];
    try {
      const userArtists = await UserArtist.findAll({
        where: { user_id: user.id },
        include: [{
          model: Artist,
          as: 'artist',
          required: false
        }]
      });
      assignedArtists = userArtists.map(ua => ua.artist).filter(a => a);
      log('artists_fetched', { artistsCount: assignedArtists.length });
    } catch (artistError) {
      console.error('Artist fetch error (non-fatal):', artistError);
      log('artists_fetch_failed', { error: artistError?.message });
    }

    // Prepare user data with RBAC information
    const userData = user.toJSON();
    userData.roles = userRoles || [];
    userData.highestRole = highestRole;
    userData.userBusinesses = userBusinesses || [];
    userData.role = highestRole?.name || userData.primary_role || userData.role || 'customer'; // For backward compatibility
    userData.assignedArtists = assignedArtists || [];

    // Check if user has admin privileges OR assigned artists (for admin panel access)
    const isAdminUser = ['super_admin', 'admin'].includes(userData.role);
    const hasAssignedArtists = assignedArtists.length > 0;
    
    if (!isAdminUser && !hasAssignedArtists) {
      log('admin_check_failed', { userId: user.id, role: userData.role, hasArtists: hasAssignedArtists });
      return res.status(403).json({
        success: false,
        error: 'Access denied. Admin privileges required or user must have assigned artists.'
      });
    }

    log('login_success', { userId: user.id });
    res.json({
      success: true,
      message: 'Login successful',
      data: {
        user: userData,
        token: idToken
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    try { console.log('[AUTH_LOGIN]', JSON.stringify({ stage: 'unhandled_error', error: error?.message })); } catch (_) {}
    res.status(500).json({
      success: false,
      error: 'Internal server error'
    });
  }
});

/**
 * @route POST /api/v1/auth/forgot-password
 * @desc Send password reset email
 * @access Public
 */
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        error: 'Email is required'
      });
    }

    // Check if user exists
    const user = await User.findOne({ where: { email } });
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Generate password reset link
    const resetLink = await FirebaseAuthService.sendPasswordResetEmail(email);

    // In a real application, you would send this link via email
    // For now, we'll return it in the response for testing
    res.json({
      success: true,
      message: 'Password reset link generated',
      data: {
        resetLink: resetLink,
        note: 'In production, this link would be sent via email'
      }
    });
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to send password reset email'
    });
  }
});

/**
 * @route GET /api/v1/auth/me
 * @desc Get current user profile
 * @access Private
 */
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const user = await User.findByPk(req.userId);
    
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    res.json({
      success: true,
      data: {
        user: user.toJSON()
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get user profile'
    });
  }
});

/**
 * @route PUT /api/v1/auth/me
 * @desc Update current user profile
 * @access Private
 */
router.put('/me', authenticateToken, async (req, res) => {
  try {
    const { firstName, lastName, phone, countryCode, address, preferences } = req.body;
    
    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (countryCode) updateData.countryCode = countryCode;

    // Update Firebase and MySQL
    const updatedUser = await FirebaseAuthService.updateUser(req.firebaseUid, updateData);

    // Update additional fields in MySQL
    const mysqlUpdateData = {};
    if (address) mysqlUpdateData.address = address;
    if (preferences) mysqlUpdateData.preferences = preferences;

    if (Object.keys(mysqlUpdateData).length > 0) {
      await User.update(mysqlUpdateData, {
        where: { id: req.userId }
      });
    }

    const finalUser = await User.findByPk(req.userId);

    res.json({
      success: true,
      message: 'Profile updated successfully',
      data: {
        user: finalUser.toJSON()
      }
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to update profile'
    });
  }
});

/**
 * @route POST /api/v1/auth/change-password
 * @desc Change user password
 * @access Private
 */
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const { newPassword } = req.body;

    if (!newPassword) {
      return res.status(400).json({
        success: false,
        error: 'New password is required'
      });
    }

    // Update password in Firebase
    const admin = require('firebase-admin');
    await admin.auth().updateUser(req.firebaseUid, {
      password: newPassword
    });

    res.json({
      success: true,
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to change password'
    });
  }
});

/**
 * @route POST /api/v1/auth/logout
 * @desc Logout user (client-side token invalidation)
 * @access Private
 */
router.post('/logout', authenticateToken, async (req, res) => {
  try {
    // In Firebase, logout is handled client-side by removing the token
    // We can optionally revoke the token server-side
    const admin = require('firebase-admin');
    await admin.auth().revokeRefreshTokens(req.firebaseUid);

    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to logout'
    });
  }
});

/**
 * @route POST /api/v1/auth/verify-token
 * @desc Verify Firebase token
 * @access Public
 */
router.post('/verify-token', async (req, res) => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({
        success: false,
        error: 'ID token is required'
      });
    }

    const decodedToken = await FirebaseAuthService.verifyToken(idToken);
    const user = await FirebaseAuthService.getUserFromToken(idToken);

    res.json({
      success: true,
      data: {
        valid: true,
        user: user.toJSON(),
        token: decodedToken
      }
    });
  } catch (error) {
    res.status(401).json({
      success: false,
      error: 'Invalid token'
    });
  }
});

/**
 * @route POST /api/v1/auth/set-role
 * @desc Set user role (Admin only)
 * @access Private (Admin)
 */
router.post('/set-role', authenticateToken, requireSystemAdmin, async (req, res) => {
  try {
    const { userId, role } = req.body;

    if (!userId || !role) {
      return res.status(400).json({
        success: false,
        error: 'User ID and role are required'
      });
    }

    const validRoles = ['super_admin', 'admin', 'business_admin', 'customer'];
    if (!validRoles.includes(role)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid role. Valid roles: ' + validRoles.join(', ')
      });
    }

    const user = await User.findByPk(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found'
      });
    }

    // Set role in Firebase and MySQL
    await FirebaseAuthService.setUserRole(user.firebase_uid, role);

    res.json({
      success: true,
      message: 'User role updated successfully',
      data: {
        userId: user.id,
        role: role
      }
    });
  } catch (error) {
    console.error('Set role error:', error);
    res.status(500).json({
      success: false,
      error: error.message || 'Failed to update user role'
    });
  }
});

module.exports = router;