'use strict';

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');

const UserModel = require('../models/user.model');
const RefreshTokenModel = require('../models/refreshToken.model');
const { AppError } = require('../utils/AppError');
const logger = require('../utils/logger');

const SALT_ROUNDS = parseInt(process.env.BCRYPT_SALT_ROUNDS, 10) || 12;

// ─── Token Helpers ────────────────────────────────────────────────────────────

const generateAccessToken = (payload) =>
  jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    issuer: 'rafiq-api',
    audience: 'rafiq-client',
  });

const generateRefreshToken = () => crypto.randomBytes(64).toString('hex');

const parseRefreshExpiry = () => {
  const val = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  const unit = val.slice(-1);
  const num = parseInt(val, 10);
  const multipliers = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
  return new Date(Date.now() + num * (multipliers[unit] || 86400000));
};

// ─── Service ──────────────────────────────────────────────────────────────────

class AuthService {
  /**
   * Register a new user
   */
  static async register({ full_name, username, email, password, userAgent, ipAddress, phone_number, req }) {
    // Check for duplicates
    const [usernameTaken, emailTaken] = await Promise.all([
      UserModel.usernameExists(username),
      UserModel.emailExists(email),
    ]);

    if (usernameTaken) {
      throw new AppError('Username is already taken', 409, 'USERNAME_TAKEN');
    }
    if (emailTaken) {
      throw new AppError('Email is already registered', 409, 'EMAIL_TAKEN');
    }

    // Split Full Name into First Name and Last Name
    let first_name = null;
    let last_name = null;
    if (full_name) {
      const parts = full_name.trim().split(/\s+/);
      if (parts.length > 0) {
        first_name = parts[0];
        if (parts.length > 1) {
          last_name = parts.slice(1).join(' ');
        }
      }
    }

    // Hash password
    const password_hash = await bcrypt.hash(password, SALT_ROUNDS);

    // Create user
    const user = await UserModel.create({
      full_name,
      username,
      email,
      password_hash,
      first_name,
      last_name,
      phone_number,
    });

    logger.info(`New user registered: ${username} (${email})`);

    // Generate tokens for automatic login
    const accessToken = generateAccessToken({
      sub: user.id,
      username: user.username,
      email: user.email,
    });

    const refreshTokenPlain = generateRefreshToken();
    const expiresAt = parseRefreshExpiry();

    await RefreshTokenModel.create({
      user_id: user.id,
      token: refreshTokenPlain,
      expiresAt,
      userAgent,
      ipAddress,
    });

    return {
      accessToken,
      refreshToken: refreshTokenPlain,
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
      user: UserModel.sanitize(user, req),
    };
  }

  /**
   * Login with username/email + password, returns access + refresh tokens
   */
  static async login({ identifier, password, userAgent, ipAddress, req }) {
    // Find user
    const user = await UserModel.findByUsernameOrEmail(identifier);

    if (!user) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    // Check status
    if (user.status === 'suspended') {
      throw new AppError('Account suspended. Contact support.', 403, 'ACCOUNT_SUSPENDED');
    }
    if (user.status !== 'active') {
      throw new AppError('Account is not active', 403, 'ACCOUNT_INACTIVE');
    }

    // Verify password
    const passwordValid = await bcrypt.compare(password, user.password_hash);
    if (!passwordValid) {
      throw new AppError('Invalid credentials', 401, 'INVALID_CREDENTIALS');
    }

    // Update last login
    await UserModel.updateLastLogin(user.id);

    // Generate tokens
    const accessToken = generateAccessToken({
      sub: user.id,
      username: user.username,
      email: user.email,
    });

    const refreshTokenPlain = generateRefreshToken();
    const expiresAt = parseRefreshExpiry();

    await RefreshTokenModel.create({
      user_id: user.id,
      token: refreshTokenPlain,
      expiresAt,
      userAgent,
      ipAddress,
    });

    logger.info(`User logged in: ${user.username}`);

    return {
      accessToken,
      refreshToken: refreshTokenPlain,
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
      user: UserModel.sanitize(user, req),
    };
  }

  /**
   * Rotate refresh token → new access + refresh token pair
   */
  static async refreshTokens({ refreshToken, userAgent, ipAddress }) {
    const record = await RefreshTokenModel.findValid(refreshToken);

    if (!record) {
      throw new AppError('Invalid or expired refresh token', 401, 'INVALID_REFRESH_TOKEN');
    }

    const user = await UserModel.findById(record.user_id);
    if (!user) {
      throw new AppError('User not found', 401, 'USER_NOT_FOUND');
    }

    // Revoke old token (rotation)
    await RefreshTokenModel.revoke(refreshToken);

    // Issue new pair
    const accessToken = generateAccessToken({
      sub: user.id,
      username: user.username,
      email: user.email,
    });

    const newRefreshToken = generateRefreshToken();
    const expiresAt = parseRefreshExpiry();

    await RefreshTokenModel.create({
      user_id: user.id,
      token: newRefreshToken,
      expiresAt,
      userAgent,
      ipAddress,
    });

    return {
      accessToken,
      refreshToken: newRefreshToken,
      expiresIn: process.env.JWT_EXPIRES_IN || '15m',
    };
  }

  /**
   * Logout: revoke the provided refresh token
   */
  static async logout(refreshToken) {
    if (refreshToken) {
      await RefreshTokenModel.revoke(refreshToken);
    }
  }

  /**
   * Logout from all devices: revoke all refresh tokens
   */
  static async logoutAll(userId) {
    await RefreshTokenModel.revokeAllForUser(userId);
    logger.info(`All sessions revoked for user: ${userId}`);
  }

  /**
   * Change password (authenticated)
   */
  static async changePassword({ userId, currentPassword, newPassword }) {
    const user = await UserModel.findById(userId);
    if (!user) {
      throw new AppError('User not found', 404, 'USER_NOT_FOUND');
    }

    const valid = await bcrypt.compare(currentPassword, user.password_hash);
    if (!valid) {
      throw new AppError('Current password is incorrect', 400, 'WRONG_PASSWORD');
    }

    if (currentPassword === newPassword) {
      throw new AppError('New password must differ from current password', 400, 'SAME_PASSWORD');
    }

    const password_hash = await bcrypt.hash(newPassword, SALT_ROUNDS);
    await UserModel.updatePassword(userId, password_hash);

    // Revoke all refresh tokens (force re-login everywhere)
    await RefreshTokenModel.revokeAllForUser(userId);

    logger.info(`Password changed for user: ${userId}`);
  }
}

module.exports = AuthService;
