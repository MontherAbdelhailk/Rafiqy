'use strict';

const { Router } = require('express');
const userController = require('../controllers/user.controller');
const { authenticate } = require('../middleware/authenticate');
const { validate } = require('../middleware/validate');
const { updateProfileValidation } = require('../validators/auth.validator');

const router = Router();

// All user routes require authentication
router.use(authenticate);

/**
 * GET /api/users/profile
 * Get full profile of the authenticated user
 */
router.get('/profile', userController.getProfile);

const upload = require('../middleware/upload');

/**
 * PATCH /api/users/profile
 * Update profile fields
 */
router.patch(
  '/profile',
  updateProfileValidation,
  validate,
  userController.updateProfile
);

/**
 * PATCH /api/users/profile/picture
 * Upload/Update profile picture
 */
router.patch(
  '/profile/picture',
  upload.single('picture'),
  userController.uploadProfilePicture
);

/**
 * DELETE /api/users/account
 * Soft-delete the authenticated user's account
 */
router.delete('/account', userController.deleteAccount);

module.exports = router;
