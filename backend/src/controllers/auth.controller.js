'use strict';

const AuthService = require('../services/auth.service');
const { AppError } = require('../utils/AppError');

// ─── Register ─────────────────────────────────────────────────────────────────
const register = async (req, res, next) => {
  try {
    const { full_name, username, email, password, phone_number } = req.body;
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;

    const result = await AuthService.register({
      full_name,
      username,
      email,
      password,
      userAgent,
      ipAddress,
      phone_number,
      req,
    });

    return res.status(201).json({
      success: true,
      message: 'Account created successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

// ─── Login ────────────────────────────────────────────────────────────────────
const login = async (req, res, next) => {
  try {
    const { identifier, password } = req.body;
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;

    const result = await AuthService.login({ identifier, password, userAgent, ipAddress, req });

    return res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

// ─── Refresh Tokens ───────────────────────────────────────────────────────────
const refreshTokens = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    const userAgent = req.headers['user-agent'];
    const ipAddress = req.ip;

    const result = await AuthService.refreshTokens({
      refreshToken: refresh_token,
      userAgent,
      ipAddress,
    });

    return res.status(200).json({
      success: true,
      message: 'Tokens refreshed successfully',
      data: result,
    });
  } catch (error) {
    next(error);
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────
const logout = async (req, res, next) => {
  try {
    const { refresh_token } = req.body;
    await AuthService.logout(refresh_token);

    return res.status(200).json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (error) {
    next(error);
  }
};

// ─── Logout All Devices ───────────────────────────────────────────────────────
const logoutAll = async (req, res, next) => {
  try {
    await AuthService.logoutAll(req.user.id);

    return res.status(200).json({
      success: true,
      message: 'Logged out from all devices successfully',
    });
  } catch (error) {
    next(error);
  }
};

// ─── Change Password ──────────────────────────────────────────────────────────
const changePassword = async (req, res, next) => {
  try {
    const { current_password, new_password } = req.body;

    await AuthService.changePassword({
      userId: req.user.id,
      currentPassword: current_password,
      newPassword: new_password,
    });

    return res.status(200).json({
      success: true,
      message: 'Password changed successfully. Please log in again.',
    });
  } catch (error) {
    next(error);
  }
};

// ─── Get Current User (me) ────────────────────────────────────────────────────
const getMe = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      data: { user: req.user },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  register,
  login,
  refreshTokens,
  logout,
  logoutAll,
  changePassword,
  getMe,
};
