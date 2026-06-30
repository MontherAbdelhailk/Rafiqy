'use strict';

const { Router } = require('express');
const { authenticate, optionalAuthenticate, requireAdmin } = require('../middleware/authenticate');
const reelUpload = require('../middleware/reel_upload');
const reelController = require('../controllers/reel.controller');

const router = Router();

// Reels
router.get('/', optionalAuthenticate, reelController.listReels);
router.post('/', authenticate, requireAdmin, reelUpload.single('video'), reelController.createReel);
router.patch('/:id', authenticate, requireAdmin, reelController.updateReel);
router.delete('/:id', authenticate, requireAdmin, reelController.deleteReel);
router.post('/:id/watch', optionalAuthenticate, reelController.watchReel);
router.post('/:id/love', authenticate, reelController.toggleLoveReel);

// Comments
router.get('/:reelId/comments', optionalAuthenticate, reelController.listReelComments);
router.post('/:reelId/comments', authenticate, reelController.addReelComment);
router.delete('/comments/:id', authenticate, reelController.deleteReelComment);
router.post('/comments/:id/like', authenticate, reelController.toggleLikeReelComment);
router.post('/comments/:id/replies', authenticate, reelController.addReelCommentReply);

module.exports = router;
