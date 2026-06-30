import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/home/widgets/post_sheet.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart'; 
import 'package:rafiq/features/home/persentation/logic/posts_cubit.dart';

import 'package:rafiq/core/widgets/app_avatar.dart';
import 'package:rafiq/core/utils/secure_storage.dart';

class AdminCreatePostWidget extends StatelessWidget {
  const AdminCreatePostWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppGenericCard(
      padding: 16.w,
      color: Colors.white,
      borderRadius: 16.r,
      shadow: BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      child: Row(
        children: [
          FutureBuilder<String?>(
            future: SecureStorage.getProfileImage(),
            builder: (context, snapshot) {
              return AppAvatar(
                imageUrl: snapshot.data,
                radius: 20.r,
              );
            },
          ),
          12.horizontalSpace,
          Expanded(
            child: GestureDetector(
              onTap: () => _showCreatePostDialog(context),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(color: const Color(0xFF96A53A), width: 1.5),
                ),
                child: Text(
                  "What's on your mind, Rafiq?",
                  style: AppTextStyles.regular14cairo.copyWith(color: Colors.grey),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePostDialog(BuildContext context) {
    final postsCubit = context.read<PostsCubit>();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: BlocProvider.value(
            value: postsCubit,
            child: const CreatePostSheet(),
          ),
        ),
      ),
    );
  }
}