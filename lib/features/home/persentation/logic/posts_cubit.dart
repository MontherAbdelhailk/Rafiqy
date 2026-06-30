import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/Posts/models/comments.model.dart';
import 'package:rafiq/features/home/persentation/logic/posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  final ApiConsumer apiConsumer;

  PostsCubit(this.apiConsumer) : super(PostsInitial());

  List<PostEntity> _postsList = [];

  Future<void> loadPosts() async {
    emit(PostsLoading());
    try {
      final response = await apiConsumer.get('posts');
      final List<dynamic> dataList = response['data'] ?? [];
      _postsList = dataList.map((json) => PostEntity.fromJson(json)).toList();
      emit(PostsLoaded(List.from(_postsList)));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> createPost(String content, {String? imagePath}) async {
    try {
      final Map<String, dynamic> data = {
        'content': content,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        data['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        );
      }

      await apiConsumer.post(
        'posts',
        data: data,
        isFormData: imagePath != null && imagePath.isNotEmpty,
      );
      await loadPosts();
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> updatePost(String postId, String content, {String? imagePath}) async {
    try {
      final Map<String, dynamic> data = {
        'content': content,
      };

      if (imagePath != null && imagePath.isNotEmpty) {
        data['image'] = await MultipartFile.fromFile(
          imagePath,
          filename: imagePath.split('/').last,
        );
      }

      await apiConsumer.patch(
        'posts/$postId',
        data: data,
        isFormData: imagePath != null && imagePath.isNotEmpty,
      );
      await loadPosts();
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await apiConsumer.delete('posts/$postId');
      _postsList.removeWhere((post) => post.id == postId);
      emit(PostsLoaded(List.from(_postsList)));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> toggleLove(String postId) async {
    try {
      final response = await apiConsumer.post('posts/$postId/love');
      final responseData = response['data'] ?? {};
      final loveCount = responseData['love_count'] ?? 0;
      final hasLoved = responseData['has_loved'] == true;

      // Update local state post item
      final index = _postsList.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentPost = _postsList[index];
        _postsList[index] = PostEntity(
          id: currentPost.id,
          content: currentPost.content,
          mediaUrl: currentPost.mediaUrl,
          authorName: currentPost.authorName,
          authorImage: currentPost.authorImage,
          timeAgo: currentPost.timeAgo,
          loveCount: loveCount,
          commentCount: currentPost.commentCount,
          hasLoved: hasLoved,
        );
        emit(PostsLoaded(List.from(_postsList)));
      }
    } catch (e) {
      // Ignored or handle error
    }
  }

  Future<void> loadComments(String postId) async {
    emit(CommentsLoading());
    try {
      final currentUserId = await SecureStorage.getUserId() ?? '';
      final currentUserRole = await SecureStorage.getRole() ?? 'user';

      final response = await apiConsumer.get('posts/$postId/comments');
      final List<dynamic> dataList = response['data'] ?? [];
      final comments = dataList.map((json) => CommentEntity.fromJson(json, currentUserId, currentUserRole)).toList();
      emit(CommentsLoaded(postId, comments));
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      await apiConsumer.post('posts/$postId/comments', data: {'content': content});
      
      // Update comment count on post locally
      final index = _postsList.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentPost = _postsList[index];
        _postsList[index] = PostEntity(
          id: currentPost.id,
          content: currentPost.content,
          mediaUrl: currentPost.mediaUrl,
          authorName: currentPost.authorName,
          authorImage: currentPost.authorImage,
          timeAgo: currentPost.timeAgo,
          loveCount: currentPost.loveCount,
          commentCount: currentPost.commentCount + 1,
          hasLoved: currentPost.hasLoved,
        );
        emit(PostsLoaded(List.from(_postsList)));
      }

      await loadComments(postId);
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await apiConsumer.delete('posts/comments/$commentId');

      // Update comment count on post locally
      final index = _postsList.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final currentPost = _postsList[index];
        _postsList[index] = PostEntity(
          id: currentPost.id,
          content: currentPost.content,
          mediaUrl: currentPost.mediaUrl,
          authorName: currentPost.authorName,
          authorImage: currentPost.authorImage,
          timeAgo: currentPost.timeAgo,
          loveCount: currentPost.loveCount,
          commentCount: currentPost.commentCount > 0 ? currentPost.commentCount - 1 : 0,
          hasLoved: currentPost.hasLoved,
        );
        emit(PostsLoaded(List.from(_postsList)));
      }

      await loadComments(postId);
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }

  Future<void> toggleLikeComment(String postId, String commentId) async {
    try {
      await apiConsumer.post('posts/comments/$commentId/like');
      await loadComments(postId);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addCommentReply(String postId, String commentId, String content) async {
    try {
      await apiConsumer.post('posts/comments/$commentId/replies', data: {'content': content});
      await loadComments(postId);
    } catch (e) {
      emit(CommentsError(e.toString()));
    }
  }
}
