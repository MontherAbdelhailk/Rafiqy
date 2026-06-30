import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/Posts/models/comments.model.dart';

import 'package:rafiq/core/widgets/app_avatar.dart';

class CommentItem extends StatelessWidget {
  final CommentEntity comment;
  final VoidCallback? onDelete; 
  final VoidCallback? onLike;
  final VoidCallback? onReply;

  const CommentItem({
    super.key,
    required this.comment,
    this.onDelete,
    this.onLike,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
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
                    Text(comment.userName, style: AppTextStyles.bold14cairo.copyWith(color: AppColors.darkblack)),
                    Text(comment.timeAgo, style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3)),
                  ],
                ),
                4.verticalSpace,
                Text(comment.text, style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey4)),
                8.verticalSpace,
                Row(
                  children: [
                    GestureDetector(
                      onTap: onLike,
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
                      onTap: onReply,
                      child: Text("Reply", style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3)),
                    ),
                    const Spacer(),
                    if (comment.canDelete)
                      IconButton(
                        onPressed: onDelete,
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