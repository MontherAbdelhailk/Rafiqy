import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';
import 'package:rafiq/core/widgets/app_comment_field.dart';
import 'package:rafiq/core/widgets/comments_item.dart';
import 'package:rafiq/features/Posts/models/comments.model.dart';
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';
import 'package:rafiq/features/home/persentation/logic/posts_state.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class CommentsView extends StatefulWidget {
  final String postId;

  const CommentsView({super.key, required this.postId});

  @override
  State<CommentsView> createState() => _CommentsViewState();
}

class _CommentsViewState extends State<CommentsView> {
  late final TextEditingController _commentController;
  CommentEntity? _replyingToComment;
  String? _currentUserImage;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    context.read<PostsCubit>().loadComments(widget.postId);
    
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
                  Text("Comments", style: AppTextStyles.bold16cairo),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: 22.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocBuilder<PostsCubit, PostsState>(
                builder: (context, state) {
                  if (state is CommentsLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryNormal));
                  } else if (state is CommentsLoaded && state.postId == widget.postId) {
                    final comments = state.comments;
                    if (comments.isEmpty) {
                      return Center(
                        child: Text("No comments yet. Be the first to comment!", 
                            style: AppTextStyles.regular14cairo.copyWith(color: Colors.grey)),
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
                            CommentItem(
                              comment: comment,
                              onDelete: () {
                                context.read<PostsCubit>().deleteComment(widget.postId, comment.id);
                              },
                              onLike: () {
                                context.read<PostsCubit>().toggleLikeComment(widget.postId, comment.id);
                              },
                              onReply: () {
                                setState(() {
                                  _replyingToComment = comment;
                                });
                              },
                            ),
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
                                                    Text(reply.userName, style: AppTextStyles.bold14inter.copyWith(color: AppColors.darkblack)),
                                                    Text(reply.timeAgo, style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3, fontSize: 10.sp)),
                                                  ],
                                                ),
                                                3.verticalSpace,
                                                Text(reply.text, style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey4, fontSize: 13.sp)),
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
                  } else if (state is CommentsError) {
                    return Center(child: Text("Error loading comments: ${state.message}", style: const TextStyle(color: Colors.red)));
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
                    context.read<PostsCubit>().addCommentReply(widget.postId, _replyingToComment!.id, text);
                    setState(() {
                      _replyingToComment = null;
                    });
                  } else {
                    context.read<PostsCubit>().addComment(widget.postId, text);
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
}