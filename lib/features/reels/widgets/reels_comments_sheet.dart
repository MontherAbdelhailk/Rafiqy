import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/app_comment_field.dart';
import 'package:rafiq/features/reels/logic/reels_cubit.dart';
import 'package:rafiq/features/reels/logic/reels_state.dart';
import 'package:rafiq/features/reels/models/reel_entity.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class ReelsCommentsSheet extends StatefulWidget {
  final String reelId;

  const ReelsCommentsSheet({super.key, required this.reelId});

  @override
  State<ReelsCommentsSheet> createState() => _ReelsCommentsSheetState();
}

class _ReelsCommentsSheetState extends State<ReelsCommentsSheet> {
  late final TextEditingController _commentController;
  ReelCommentEntity? _replyingToComment;
  String? _currentUserImage;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    context.read<ReelsCubit>().loadComments(widget.reelId);

    // Load current user profile picture for the input field avatar
    SecureStorage.getProfileImage().then((url) {
      if (mounted) {
        setState(() {
          _currentUserImage = url;
        });
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Comments", style: AppTextStyles.bold16cairo),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 22.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<ReelsCubit, ReelsState>(
                buildWhen: (previous, current) =>
                    current is ReelCommentsLoading ||
                    current is ReelCommentsLoaded ||
                    current is ReelCommentsError,
                builder: (context, state) {
                  if (state is ReelCommentsLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primaryNormal),
                    );
                  } else if (state is ReelCommentsLoaded && state.reelId == widget.reelId) {
                    final comments = state.comments;
                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          "No comments yet. Be the first to comment!",
                          style: AppTextStyles.regular14cairo.copyWith(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCommentItem(comment),
                            // Render Replies
                            if (comment.replies.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(left: 36.w, bottom: 8.h),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: comment.replies.length,
                                  itemBuilder: (context, rIndex) {
                                    final reply = comment.replies[rIndex];
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 6.h),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AppAvatar(
                                            imageUrl: reply.userImage,
                                            radius: 14.r,
                                            name: reply.userName,
                                          ),
                                          10.horizontalSpace,
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      reply.userName,
                                                      style: AppTextStyles.bold14inter.copyWith(color: AppColors.darkblack),
                                                    ),
                                                    Text(
                                                      reply.timeAgo,
                                                      style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3, fontSize: 10.sp),
                                                    ),
                                                  ],
                                                ),
                                                3.verticalSpace,
                                                Text(
                                                  reply.text,
                                                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey4, fontSize: 13.sp),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  } else if (state is ReelCommentsError) {
                    return Center(
                      child: Text(
                        "Error loading comments: ${state.message}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            if (_replyingToComment != null)
              Container(
                color: Colors.grey.shade100,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Replying to @${_replyingToComment!.userName}",
                      style: AppTextStyles.regular12inter.copyWith(color: AppColors.primaryNormal),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToComment = null;
                        });
                      },
                      child: Icon(Icons.cancel, size: 16.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            AppCommentInput(
              controller: _commentController,
              userImage: _currentUserImage,
              onSend: () {
                final text = _commentController.text.trim();
                if (text.isNotEmpty) {
                  if (_replyingToComment != null) {
                    context.read<ReelsCubit>().addCommentReply(widget.reelId, _replyingToComment!.id, text);
                    setState(() {
                      _replyingToComment = null;
                    });
                  } else {
                    context.read<ReelsCubit>().addComment(widget.reelId, text);
                  }
                  _commentController.clear();
                  FocusScope.of(context).unfocus();
                }
              },
            ),
            10.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildCommentItem(ReelCommentEntity comment) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: comment.userImage,
            radius: 20.r,
            name: comment.userName,
          ),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      comment.userName,
                      style: AppTextStyles.bold14cairo.copyWith(color: AppColors.darkblack),
                    ),
                    Text(
                      comment.timeAgo,
                      style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3),
                    ),
                  ],
                ),
                4.verticalSpace,
                Text(
                  comment.text,
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey4),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        context.read<ReelsCubit>().toggleLikeComment(widget.reelId, comment.id);
                      },
                      child: Icon(
                        comment.hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                        size: 16.sp,
                        color: comment.hasLiked ? AppColors.primaryNormal : AppColors.grey3,
                      ),
                    ),
                    4.horizontalSpace,
                    Text('${comment.likesCount}', style: const TextStyle(color: Colors.grey)),
                    20.horizontalSpace,
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _replyingToComment = comment;
                        });
                      },
                      child: Text("Reply", style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3)),
                    ),
                    const Spacer(),
                    if (comment.canDelete)
                      IconButton(
                        onPressed: () {
                          context.read<ReelsCubit>().deleteComment(widget.reelId, comment.id);
                        },
                        icon: Icon(Icons.delete_outline, color: AppColors.grey3, size: 20.sp),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
