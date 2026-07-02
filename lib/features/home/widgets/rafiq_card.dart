import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/app_avatar.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart';
import 'package:rafiq/features/Posts/models/comments.model.dart';
import 'package:rafiq/features/Posts/peresentation/comments_view.dart';
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';
import 'package:rafiq/features/home/widgets/post_sheet.dart';
import 'package:share_plus/share_plus.dart';

class RafiqPostCard extends StatelessWidget {
  final PostEntity post;
  final bool isAdmin;

  const RafiqPostCard({super.key, required this.post, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return AppGenericCard(
      padding: 16.w,
      color: Colors.white,
      borderRadius: 16.r,
      border: Border.all(color: Colors.grey.shade200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context), 
          16.verticalSpace,
          _buildContent(),
          20.verticalSpace,
       const   Divider(
thickness: 0.2,  
  height: 1.0,            ),
                    10.verticalSpace,

          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        AppAvatar(
          imageUrl: post.authorImage,
          radius: 20.r,
          name: post.authorName,
        ),
        12.horizontalSpace,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.authorName, style: AppTextStyles.extrabold16cairo),
              Text("${post.timeAgo} • Parenting Specialist", 
                  style: AppTextStyles.regular16cairo.copyWith(color: Colors.grey, fontSize: 12.sp)),
            ],
          ),
        ),
        if (isAdmin) ...[

          InkWell(
  onTap:() => _showEditPost(context),
  child: Padding(
    padding: EdgeInsets.all(4.w),
    child: const Icon(Icons.edit_outlined, color: Colors.lightGreen, size: 20),
  ),
),

          InkWell(
  onTap: () {
              context.read<PostsCubit>().deletePost(post.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Post deleted successfully")),
              );
            },
            
  child: Padding(
    padding: EdgeInsets.all(4.w),
            child: const Icon(Icons.delete_outline, color: Colors.red),
  ),
),



        ],
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      post.content,
      style: AppTextStyles.regular14cairo.copyWith(height: 1.5),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            context.read<PostsCubit>().toggleLove(post.id);
          },
          child: Icon(
            post.hasLoved ? Icons.favorite : Icons.favorite_border,
            size: 25.sp,
            color: post.hasLoved ? AppColors.primaryNormal : AppColors.grey12,
          ),
        ),
        4.horizontalSpace,
        Text('${post.loveCount}', style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12)),
        8.horizontalSpace,
InkWell(
  onTap: () => _showComments(context),
  customBorder: const CircleBorder(), // عشان الـ Ripple effect تطلع دائرية
  child: Padding(
    padding: const EdgeInsets.all(4.0), // تحكمي في مساحة الضغط براحتك
    child: Icon(
      Icons.chat_bubble_outline, 
      color: AppColors.grey12, 
      size: 25.sp,
    ),
  ),
),
        4.horizontalSpace,
        Text('${post.commentCount}', style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12)),
        const Spacer(),
        GestureDetector(
          onTap: () {
            SharePlus.instance.share(
              ShareParams(
                text: post.content,
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, size: 20.sp, color: AppColors.grey12),
              4.horizontalSpace,
               Text("Share", style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey12)),
            ],
          ),
        ),
      ],
    );
  }

  void _showComments(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: postsCubit,
        child: CommentsView(postId: post.id),
      ),
    );
  }

  void _showEditPost(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: postsCubit,
        child: CreatePostSheet(postToEdit: post),
      ),
    );
  }
}