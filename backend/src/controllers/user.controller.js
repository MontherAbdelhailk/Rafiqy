'use strict';

const UserModel = require('../models/user.model');
const { AppError } = require('../utils/AppError');

// ─── Get Profile ──────────────────────────────────────────────────────────────
const getProfile = async (req, res, next) => {
  try {
    const user = await UserModel.findById(req.user.id);
    if (!user) {
      return next(new AppError('User not found', 404, 'USER_NOT_FOUND'));
    }

    return res.status(200).json({
      success: true,
      data: { user: UserModel.sanitize(user, req) },
    });
  } catch (error) {
    next(error);
  }
};

// ─── Update Profile ───────────────────────────────────────────────────────────
const updateProfile = async (req, res, next) => {
  try {
    const {
      first_name,
      last_name,
      profile_picture,
      status, // Client sends 'status' (Single/Married/Divorced)
      age,
      phone, // Client sends 'phone'
      children_count,
      bio
    } = req.body;

    const updated = await UserModel.updateProfile(req.user.id, {
      first_name,
      last_name,
      profile_picture,
      marital_status: status,
      age: age ? parseInt(age, 10) : undefined,
      phone_number: phone,
      children_count: children_count ? parseInt(children_count, 10) : 0,
      bio
    });

    if (!updated) {
      return next(new AppError('User not found', 404, 'USER_NOT_FOUND'));
    }

    return res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: { user: UserModel.sanitize(updated, req) },
    });
  } catch (error) {
    next(error);
  }
};

// ─── Delete Account ───────────────────────────────────────────────────────────
const deleteAccount = async (req, res, next) => {
  try {
    const deleted = await UserModel.softDelete(req.user.id);
    if (!deleted) {
      return next(new AppError('User not found', 404, 'USER_NOT_FOUND'));
    }

    return res.status(200).json({
      success: true,
      message: 'Account deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};

// ─── Upload Profile Picture ───────────────────────────────────────────────────
const uploadProfilePicture = async (req, res, next) => {
  try {
    if (!req.file) {
      return next(new AppError('Please upload an image file', 400, 'NO_FILE_UPLOADED'));
    }

    // Save relative URL path to DB
    const relativePath = `/uploads/${req.file.filename}`;
    const updated = await UserModel.updateProfile(req.user.id, {
      profile_picture: relativePath,
    });

    return res.status(200).json({
      success: true,
      message: 'Profile picture uploaded successfully',
      data: {
        profile_picture: relativePath,
        user: UserModel.sanitize(updated, req),
      },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { getProfile, updateProfile, deleteAccount, uploadProfilePicture };
