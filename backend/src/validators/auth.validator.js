'use strict';

const { body } = require('express-validator');

const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

const registerValidation = [
  body('full_name')
    .trim()
    .notEmpty().withMessage('Full name is required')
    .isLength({ min: 2, max: 100 }).withMessage('Full name must be 2–100 characters'),

  body('username')
    .trim()
    .notEmpty().withMessage('Username is required')
    .isLength({ min: 3, max: 30 }).withMessage('Username must be 3–30 characters')
    .matches(/^[a-zA-Z0-9_]+$/).withMessage('Username may only contain letters, numbers, and underscores')
    .toLowerCase(),

  body('email')
    .trim()
    .notEmpty().withMessage('Email is required')
    .isEmail().withMessage('Email must be a valid email address')
    .normalizeEmail(),

  body('password')
    .notEmpty().withMessage('Password is required')
    .matches(PASSWORD_REGEX)
    .withMessage(
      'Password must be at least 8 characters and include uppercase, lowercase, number, and special character'
    ),

  body('confirm_password')
    .notEmpty().withMessage('Password confirmation is required')
    .custom((value, { req }) => {
      if (value !== req.body.password) {
        throw new Error('Passwords do not match');
      }
      return true;
    }),
];

const loginValidation = [
  body('identifier')
    .trim()
    .notEmpty().withMessage('Username or email is required'),

  body('password')
    .notEmpty().withMessage('Password is required'),
];

const refreshTokenValidation = [
  body('refresh_token')
    .notEmpty().withMessage('Refresh token is required')
    .isString().withMessage('Refresh token must be a string'),
];

const changePasswordValidation = [
  body('current_password')
    .notEmpty().withMessage('Current password is required'),

  body('new_password')
    .notEmpty().withMessage('New password is required')
    .matches(PASSWORD_REGEX)
    .withMessage(
      'New password must be at least 8 characters and include uppercase, lowercase, number, and special character'
    ),

  body('confirm_new_password')
    .notEmpty().withMessage('Password confirmation is required')
    .custom((value, { req }) => {
      if (value !== req.body.new_password) {
        throw new Error('New passwords do not match');
      }
      return true;
    }),
];

const updateProfileValidation = [
  body('first_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('First name must be 2–50 characters'),

  body('last_name')
    .optional()
    .trim()
    .isLength({ min: 2, max: 50 }).withMessage('Last name must be 2–50 characters'),

  body('profile_picture')
    .optional()
    .trim()
    .isString(),

  body('status')
    .optional()
    .isIn(['Single', 'Married', 'Divorced'])
    .withMessage('Status must be either Single, Married, or Divorced'),

  body('age')
    .optional()
    .isInt({ min: 0, max: 120 })
    .withMessage('Age must be a valid number between 0 and 120'),

  body('phone')
    .optional()
    .trim()
    .isString(),

  body('children_count')
    .custom((value, { req }) => {
      // If status is Married, children_count must be supplied and be a valid integer >= 0
      const status = req.body.status;
      if (status === 'Married') {
        if (value === undefined || value === null) {
          throw new Error('Number of children is required when status is Married');
        }
        const count = parseInt(value, 10);
        if (isNaN(count) || count < 0) {
          throw new Error('Number of children must be a valid positive number');
        }
      }
      return true;
    }),

  body('bio')
    .optional()
    .trim()
    .isString(),
];

module.exports = {
  registerValidation,
  loginValidation,
  refreshTokenValidation,
  changePasswordValidation,
  updateProfileValidation,
};
