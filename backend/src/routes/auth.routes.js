'use strict';

const { Router } = require('express');
const authController = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/authenticate');
const { authLimiter } = require('../middleware/rateLimiter');
const { validate } = require('../middleware/validate');
const {
  registerValidation,
  loginValidation,
  refreshTokenValidation,
  changePasswordValidation,
} = require('../validators/auth.validator');

const router = Router();

// ─── Public Routes (rate-limited) ─────────────────────────────────────────────

/**
 * POST /api/auth/register
 * Register a new user account
 */
router.post(
  '/register',
  authLimiter,
  registerValidation,
  validate,
  authController.register
);

/**
 * POST /api/auth/login
 * Login with username/email + password
 */
router.post(
  '/login',
  authLimiter,
  loginValidation,
  validate,
  authController.login
);

/**
 * POST /api/auth/refresh
 * Exchange a refresh token for a new access + refresh token pair
 */
router.post(
  '/refresh',
  refreshTokenValidation,
  validate,
  authController.refreshTokens
);

/**
 * POST /api/auth/logout
 * Revoke the provided refresh token
 */
router.post('/logout', authController.logout);

// ─── Protected Routes ─────────────────────────────────────────────────────────

/**
 * POST /api/auth/logout-all
 * Revoke all refresh tokens (logout everywhere)
 */
router.post('/logout-all', authenticate, authController.logoutAll);

/**
 * GET /api/auth/me
 * Get the current authenticated user's basic info
 */
router.get('/me', authenticate, authController.getMe);

/**
 * PATCH /api/auth/change-password
 * Change password (requires current password)
 */
router.patch(
  '/change-password',
  authenticate,
  changePasswordValidation,
  validate,
  authController.changePassword
);

module.exports = router;
