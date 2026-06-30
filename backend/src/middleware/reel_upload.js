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
    // Generate unique name: reel-userId-timestamp.ext
    const ext = path.extname(file.originalname);
    const userId = req.user ? req.user.id : 'anonymous';
    cb(null, `reel-${userId}-${Date.now()}${ext}`);
  },
});

// File filter (videos only - mp4)
const fileFilter = (req, file, cb) => {
  const allowedTypes = /mp4/;
  const mimetype = allowedTypes.test(file.mimetype);
  const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());

  if (mimetype && extname) {
    return cb(null, true);
  }
  cb(new AppError('Only MP4 videos are allowed', 400, 'INVALID_FILE_TYPE'), false);
};

const maxVideoSize = parseInt(process.env.MAX_VIDEO_SIZE, 10) || 300 * 1024 * 1024; // Default 300MB

const reelUpload = multer({
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: maxVideoSize,
  },
});

module.exports = reelUpload;
