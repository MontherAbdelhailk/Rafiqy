import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/features/video/domain/entities/video_entity.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/admin_video_state.dart';
import 'package:rafiq/features/video/persentation/widgets/custom_category_tabbar.dart';

class ParentingAdminView extends StatelessWidget {
  const ParentingAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AdminVideoCubit>()..fetchAdminVideos(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("Parenting List ", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            SizedBox(height: 10.h),
            const StaticCategoryTabBar(),
            SizedBox(height: 20.h),
            Expanded(
              child: BlocListener<AdminVideoCubit, AdminVideoState>(
                listener: (context, state) {
                  if (state is DeleteVideoSuccess) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم حذف الفيديو بنجاح"), backgroundColor: Colors.redAccent),
                    );
                  } else if (state is DeleteVideoError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.black),
                    );
                  }
                },
                child: BlocBuilder<AdminVideoCubit, AdminVideoState>(
                  builder: (context, state) {
                    if (state is AdminFetchLoading) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primaryNormal));
                    } else if (state is AdminFetchSuccess) {
                      return _buildVideosList(state.videos);
                    } else if (state is AdminFetchError) {
                      return Center(child: Text(state.message));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 150, bottom: 40),
          child: Builder(
            builder: (buttonContext) {
              return FloatingActionButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                backgroundColor: const Color(0xFFC4D35D),
                onPressed: () {
                                context.push(
                                  
                                  AppRouter.uploadVideoMediaView,
);

                },
                child: const Icon(Icons.add, color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideosList(List<VideoEntity> videos) {
    if (videos.isEmpty) {
      return const Center(child: Text("لا توجد فيديوهات حالياً"));
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return _buildAdminListItem(context, video);
      },
    );
  }

  Widget _buildAdminListItem(BuildContext context, VideoEntity video) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.only(bottom: 12.h),
        shape: const RoundedRectangleBorder(),
        child: ListTile(
          contentPadding: EdgeInsets.all(8.w),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.asset(
              video.thumbnailUrl,
              width: 60.w,
              height: 60.h,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.video_library)),
            ),
          ),
          title: Text(
            video.title,
            style: AppTextStyles.bold16cairo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text("Last edited: Just now", style: AppTextStyles.regular16cairo),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.lightGreen),
                onPressed: () {
                  context.push(
                    AppRouter.createPostView,
                    extra: {
                      'videoToEdit': video,
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  context.read<AdminVideoCubit>().removeVideo(video.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}