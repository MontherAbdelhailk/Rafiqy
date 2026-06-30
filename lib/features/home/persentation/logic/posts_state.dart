import 'package:rafiq/features/Posts/models/comments.model.dart';

abstract class PostsState {}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<PostEntity> posts;
  PostsLoaded(this.posts);
}

class PostsError extends PostsState {
  final String message;
  PostsError(this.message);
}

class CommentsLoading extends PostsState {}

class CommentsLoaded extends PostsState {
  final String postId;
  final List<CommentEntity> comments;
  CommentsLoaded(this.postId, this.comments);
}

class CommentsError extends PostsState {
  final String message;
  CommentsError(this.message);
}
