import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/reels/models/reel_entity.dart';
import 'package:rafiq/features/reels/logic/reels_state.dart';

class ReelsCubit extends Cubit<ReelsState> {
  final ApiConsumer apiConsumer;

  ReelsCubit(this.apiConsumer) : super(ReelsInitial());

  List<ReelEntity> _reelsList = [];
  int _offset = 0;
  final int _limit = 10;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;

  Future<void> loadReels({bool isRefresh = false}) async {
    if (isRefresh) {
      _offset = 0;
      _hasReachedMax = false;
      _reelsList = [];
    }

    if (_hasReachedMax || _isLoadingMore) return;

    if (_offset == 0) {
      emit(ReelsLoading());
    } else {
      _isLoadingMore = true;
    }

    try {
      final response = await apiConsumer.get('reels', queryParameters: {
        'limit': _limit,
        'offset': _offset,
      });

      final List<dynamic> dataList = response['data'] ?? [];
      final List<ReelEntity> fetchedReels = dataList.map((json) => ReelEntity.fromJson(json)).toList();

      if (fetchedReels.length < _limit) {
        _hasReachedMax = true;
      }

      _reelsList.addAll(fetchedReels);
      _offset += fetchedReels.length;

      emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
    } catch (e) {
      emit(ReelsError(e.toString()));
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> publishReel(XFile videoFile, String caption, bool isPublic, bool allowComments) async {
    try {
      final Map<String, dynamic> data = {
        'caption': caption,
        'is_public': isPublic.toString(),
        'comments_enabled': allowComments.toString(),
        'video': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.name,
        ),
      };

      await apiConsumer.post(
        'reels',
        data: data,
        isFormData: true,
      );
      await loadReels(isRefresh: true);
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> deleteReel(String id) async {
    try {
      await apiConsumer.delete('reels/$id');
      _reelsList.removeWhere((reel) => reel.id == id);
      emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
    } catch (e) {
      emit(ReelsError(e.toString()));
    }
  }

  Future<void> watchReel(String id) async {
    try {
      await apiConsumer.post('reels/$id/watch');
      final index = _reelsList.indexWhere((r) => r.id == id);
      if (index != -1) {
        final current = _reelsList[index];
        _reelsList[index] = ReelEntity(
          id: current.id,
          caption: current.caption,
          videoUrl: current.videoUrl,
          thumbnailUrl: current.thumbnailUrl,
          isPublic: current.isPublic,
          commentsEnabled: current.commentsEnabled,
          viewCount: current.viewCount + 1,
          authorName: current.authorName,
          authorImage: current.authorImage,
          loveCount: current.loveCount,
          commentCount: current.commentCount,
          hasLoved: current.hasLoved,
        );
        emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> toggleLoveReel(String id) async {
    try {
      final response = await apiConsumer.post('reels/$id/love');
      final responseData = response['data'] ?? {};
      final loveCount = responseData['love_count'] ?? 0;
      final hasLoved = responseData['has_loved'] == true;

      final index = _reelsList.indexWhere((r) => r.id == id);
      if (index != -1) {
        final current = _reelsList[index];
        _reelsList[index] = ReelEntity(
          id: current.id,
          caption: current.caption,
          videoUrl: current.videoUrl,
          thumbnailUrl: current.thumbnailUrl,
          isPublic: current.isPublic,
          commentsEnabled: current.commentsEnabled,
          viewCount: current.viewCount,
          authorName: current.authorName,
          authorImage: current.authorImage,
          loveCount: loveCount,
          commentCount: current.commentCount,
          hasLoved: hasLoved,
        );
        emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
      }
    } catch (e) {
      // Ignored
    }
  }

  Future<void> loadComments(String reelId) async {
    emit(ReelCommentsLoading());
    try {
      final currentUserId = await SecureStorage.getUserId() ?? '';
      final currentUserRole = await SecureStorage.getRole() ?? 'user';

      final response = await apiConsumer.get('reels/$reelId/comments');
      final List<dynamic> dataList = response['data'] ?? [];
      final comments = dataList.map((json) => ReelCommentEntity.fromJson(json, currentUserId, currentUserRole)).toList();
      emit(ReelCommentsLoaded(reelId, comments));
    } catch (e) {
      emit(ReelCommentsError(e.toString()));
    }
  }

  Future<void> addComment(String reelId, String content) async {
    try {
      await apiConsumer.post('reels/$reelId/comments', data: {'content': content});

      // Update comment count locally
      final index = _reelsList.indexWhere((r) => r.id == reelId);
      if (index != -1) {
        final current = _reelsList[index];
        _reelsList[index] = ReelEntity(
          id: current.id,
          caption: current.caption,
          videoUrl: current.videoUrl,
          thumbnailUrl: current.thumbnailUrl,
          isPublic: current.isPublic,
          commentsEnabled: current.commentsEnabled,
          viewCount: current.viewCount,
          authorName: current.authorName,
          authorImage: current.authorImage,
          loveCount: current.loveCount,
          commentCount: current.commentCount + 1,
          hasLoved: current.hasLoved,
        );
        emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
      }

      await loadComments(reelId);
    } catch (e) {
      emit(ReelCommentsError(e.toString()));
    }
  }

  Future<void> deleteComment(String reelId, String commentId) async {
    try {
      await apiConsumer.delete('reels/comments/$commentId');

      // Update comment count locally
      final index = _reelsList.indexWhere((r) => r.id == reelId);
      if (index != -1) {
        final current = _reelsList[index];
        _reelsList[index] = ReelEntity(
          id: current.id,
          caption: current.caption,
          videoUrl: current.videoUrl,
          thumbnailUrl: current.thumbnailUrl,
          isPublic: current.isPublic,
          commentsEnabled: current.commentsEnabled,
          viewCount: current.viewCount,
          authorName: current.authorName,
          authorImage: current.authorImage,
          loveCount: current.loveCount,
          commentCount: current.commentCount > 0 ? current.commentCount - 1 : 0,
          hasLoved: current.hasLoved,
        );
        emit(ReelsLoaded(List.from(_reelsList), hasReachedMax: _hasReachedMax));
      }

      await loadComments(reelId);
    } catch (e) {
      emit(ReelCommentsError(e.toString()));
    }
  }

  Future<void> toggleLikeComment(String reelId, String commentId) async {
    try {
      await apiConsumer.post('reels/comments/$commentId/like');
      await loadComments(reelId);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> addCommentReply(String reelId, String commentId, String content) async {
    try {
      await apiConsumer.post('reels/comments/$commentId/replies', data: {'content': content});
      await loadComments(reelId);
    } catch (e) {
      emit(ReelCommentsError(e.toString()));
    }
  }
}
