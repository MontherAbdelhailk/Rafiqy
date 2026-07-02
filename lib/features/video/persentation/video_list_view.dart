import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/video/persentation/logic/video_list_cubit.dart';
import 'package:rafiq/features/video/persentation/logic/video_list_state.dart';
import 'package:rafiq/features/video/persentation/video_details_view.dart';
import 'package:rafiq/features/video/persentation/widgets/video_card.dart';

class VideosListView extends StatelessWidget {
  final String stageTitle;
  const VideosListView({super.key, required this.stageTitle});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<VideosListCubit>()..getVideos(stageTitle),
      child: _VideosListBody(stageTitle: stageTitle),
    );
  }
}

class _VideosListBody extends StatelessWidget {
  final String stageTitle;
  const _VideosListBody({required this.stageTitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        surfaceTintColor: AppColors.babypink,
        title: Text(
          stageTitle,
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
        ),
        centerTitle: true,
        backgroundColor: AppColors.babypink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<bool>(
        future: SecureStorage.isAdmin(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data == true;
          return BlocBuilder<VideosListCubit, VideosListState>(
            builder: (context, state) {
              if (state is VideosListLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormalActive),
                  ),
                );
              } else if (state is VideosListSuccess) {
                final videos = state.videos;
                if (videos.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.video_library_outlined,
                            size: 80.r,
                            color: AppColors.grey8.withValues(alpha: 0.5),
                          ),
                          16.verticalSpace,
                          Text(
                            "No Videos Found",
                            style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
                          ),
                          8.verticalSpace,
                          Text(
                            "There are currently no videos available for this stage. Please check back later.",
                            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.all(24.w),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return VideoCard(
                      video: video,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoDetailsView(video: video),
                        ),
                      ),
                      onEdit: isAdmin
                          ? () async {
                              await context.push(
                                AppRouter.createPostView,
                                extra: {
                                  'videoToEdit': video,
                                },
                              );
                              if (context.mounted) {
                                context.read<VideosListCubit>().getVideos(stageTitle);
                              }
                            }
                          : null,
                      onDelete: isAdmin
                          ? () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("حذف الفيديو"),
                                  content: const Text("هل أنت متأكد من رغبتك في حذف هذا الفيديو؟"),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text("إلغاء"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text("حذف", style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && context.mounted) {
                                context.read<VideosListCubit>().removeVideo(video.id, stageTitle);
                              }
                            }
                          : null,
                    );
                  },
                );
              } else if (state is VideosListError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 60.r,
                          color: AppColors.errorNormal,
                        ),
                        16.verticalSpace,
                        Text(
                          "Failed to load videos",
                          style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
                        ),
                        8.verticalSpace,
                        Text(
                          state.message,
                          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                          textAlign: TextAlign.center,
                        ),
                        24.verticalSpace,
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNormalActive,
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          onPressed: () {
                            context.read<VideosListCubit>().getVideos(stageTitle);
                          },
                          child: Text(
                            "Try Again",
                            style: AppTextStyles.bold14cairo.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}