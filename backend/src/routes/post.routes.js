'use strict';

const { Router } = require('express');
const { authenticate, optionalAuthenticate, requireAdmin } = require('../middleware/authenticate');
const upload = require('../middleware/upload');
const postController = require('../controllers/post.controller');

const router = Router();

// Posts
router.get('/', optionalAuthenticate, postController.listPosts);
router.post('/', authenticate, requireAdmin, upload.single('image'), postController.createPost);
router.patch('/:id', authenticate, requireAdmin, upload.single('image'), postController.updatePost);
router.delete('/:id', authenticate, requireAdmin, postController.deletePost);
router.post('/:id/love', authenticate, postController.toggleLovePost);

// Comments
router.get('/:postId/comments', optionalAuthenticate, postController.listComments);
router.post('/:postId/comments', authenticate, postController.addComment);
router.delete('/comments/:id', authenticate, postController.deleteComment);
router.post('/comments/:id/like', authenticate, postController.toggleLikeComment);
router.post('/comments/:id/replies', authenticate, postController.addCommentReply);

module.exports = router;
