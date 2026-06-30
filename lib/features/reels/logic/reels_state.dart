import 'package:rafiq/features/reels/models/reel_entity.dart';

abstract class ReelsState {}

class ReelsInitial extends ReelsState {}

class ReelsLoading extends ReelsState {}

class ReelsLoaded extends ReelsState {
  final List<ReelEntity> reels;
  final bool hasReachedMax;
  ReelsLoaded(this.reels, {this.hasReachedMax = false});
}

class ReelsError extends ReelsState {
  final String message;
  ReelsError(this.message);
}

class ReelCommentsLoading extends ReelsState {}

class ReelCommentsLoaded extends ReelsState {
  final String reelId;
  final List<ReelCommentEntity> comments;
  ReelCommentsLoaded(this.reelId, this.comments);
}

class ReelCommentsError extends ReelsState {
  final String message;
  ReelCommentsError(this.message);
}
