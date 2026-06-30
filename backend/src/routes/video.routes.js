'use strict';

const express = require('express');
const router = express.Router();
const videoController = require('../controllers/video.controller');
const { authenticate, optionalAuthenticate, requireAdmin } = require('../middleware/authenticate');
const videoUpload = require('../middleware/video_upload');

const uploadFields = videoUpload.fields([
  { name: 'video', maxCount: 1 },
  { name: 'cover_image', maxCount: 1 },
]);

// User endpoints
router.get('/categories', optionalAuthenticate, videoController.getCategories);
router.get('/list/:stageTitle', optionalAuthenticate, videoController.getVideosList);
router.post('/:id/like', authenticate, videoController.toggleLikeVideo);
router.post('/:id/watch', authenticate, videoController.watchVideo);

// Admin endpoints
router.post('/', authenticate, requireAdmin, uploadFields, videoController.createVideo);
router.patch('/:id', authenticate, requireAdmin, uploadFields, videoController.updateVideo);
router.delete('/:id', authenticate, requireAdmin, videoController.deleteVideo);

module.exports = router;
