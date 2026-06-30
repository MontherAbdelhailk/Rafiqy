'use strict';

const jwt = require('jsonwebtoken');
const { AppError } = require('../utils/AppError');
const UserModel = require('../models/user.model');

/**
 * Middleware: Verify JWT access token
 * Attaches req.user = { id, username, email } on success
 */
const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('Access token required', 401, 'TOKEN_MISSING'));
    }

    const token = authHeader.slice(7); // Remove "Bearer "

    let decoded;
    try {
      decoded = jwt.verify(token, process.env.JWT_SECRET, {
        issuer: 'rafiq-api',
        audience: 'rafiq-client',
      });
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return next(new AppError('Access token expired', 401, 'TOKEN_EXPIRED'));
      }
      return next(new AppError('Invalid access token', 401, 'TOKEN_INVALID'));
    }

    // Fetch fresh user from DB to ensure account is still active
    const user = await UserModel.findById(decoded.sub);
    if (!user) {
      return next(new AppError('User no longer exists', 401, 'USER_NOT_FOUND'));
    }
    if (user.status !== 'active') {
      return next(new AppError('Account is not active', 403, 'ACCOUNT_INACTIVE'));
    }

    req.user = UserModel.sanitize(user, req);

    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware: Optional authentication (doesn't fail if no token)
 */
const optionalAuthenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.slice(7);
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET, {
        issuer: 'rafiq-api',
        audience: 'rafiq-client',
      });
      const user = await UserModel.findById(decoded.sub);
      if (user && user.status === 'active') {
        req.user = UserModel.sanitize(user, req);
      }
    } catch (_) {
      // Ignore token errors for optional auth
    }
    next();
  } catch (error) {
    next(error);
  }
};

/**
 * Middleware: Check user role
 */
const requireRole = (role) => (req, res, next) => {
  if (!req.user || req.user.role !== role) {
    return next(new AppError('Forbidden: Access denied', 403, 'FORBIDDEN'));
  }
  next();
};

const requireAdmin = requireRole('admin');

module.exports = { authenticate, optionalAuthenticate, requireRole, requireAdmin };
