'use strict';

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { AppError } = require('../utils/AppError');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// Storage engine configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const userId = req.user ? req.user.id : 'anonymous';
    const prefix = file.fieldname === 'video' ? 'video' : 'cover';
    cb(null, `${prefix}-${userId}-${Date.now()}${ext}`);
  },
});

// File filter
const fileFilter = (req, file, cb) => {
  if (file.fieldname === 'video') {
    const allowedTypes = /mp4/;
    const mimetype = allowedTypes.test(file.mimetype);
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new AppError('Only MP4 videos are allowed', 400, 'INVALID_VIDEO_TYPE'), false);
  } else if (file.fieldname === 'cover_image') {
    const allowedTypes = /jpeg|jpg|png|webp/;
    const mimetype = allowedTypes.test(file.mimetype);
    const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
    if (mimetype && extname) {
      return cb(null, true);
    }
    cb(new AppError('Only JPEG, JPG, PNG, and WEBP cover images are allowed', 400, 'INVALID_IMAGE_TYPE'), false);
  } else {
    cb(new AppError('Unexpected field name', 400, 'UNEXPECTED_FIELD'), false);
  }
};

const maxVideoSize = parseInt(process.env.MAX_VIDEO_SIZE, 10) || 300 * 1024 * 1024; // Up to 300MB

const videoUpload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: maxVideoSize,
  },
});

module.exports = videoUpload;
