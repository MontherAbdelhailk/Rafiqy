import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:video_player/video_player.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/networking/api_consumer.dart';
import 'package:share_plus/share_plus.dart';
import '../domain/entities/video_entity.dart';
import 'widgets/video_controls_overlay.dart';
import 'fullscreen_video_view.dart';

class VideoDetailsView extends StatefulWidget {
  final VideoEntity video;
  const VideoDetailsView({super.key, required this.video});

  @override
  State<VideoDetailsView> createState() => _VideoDetailsViewState();
}

class _VideoDetailsViewState extends State<VideoDetailsView> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  late int _likesCount;
  late int _viewsCount;
  late bool _hasLiked;
  bool _hasTriggeredView = false;

  @override
  void initState() {
    super.initState();
    _likesCount = int.tryParse(widget.video.likes) ?? 0;
    _viewsCount = int.tryParse(widget.video.views) ?? 0;
    _hasLiked = widget.video.hasLiked;

    final absoluteVideoUrl = _getVideoUrl(widget.video.videoUrl);
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(absoluteVideoUrl),
    )..initialize().then((_) {
        if (mounted) {
          setState(() {
            _isInitialized = true;
          });
          _controller.play();
          _triggerView();
        }
      });
  }

  String _getVideoUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return 'http://10.238.1.136:5000$cleanPath';
  }

  Future<void> _triggerView() async {
    if (_hasTriggeredView) return;
    _hasTriggeredView = true;
    try {
      final response = await getIt<ApiConsumer>().post("videos/${widget.video.id}/watch");
      final views = response['data']?['views_count'];
      if (views != null && mounted) {
        setState(() {
          _viewsCount = views;
        });
      }
    } catch (e) {
      debugPrint("Error logging view: $e");
    }
  }

  Future<void> _toggleLike() async {
    try {
      final response = await getIt<ApiConsumer>().post("videos/${widget.video.id}/like");
      final likes = response['data']?['likes_count'];
      final liked = response['data']?['has_liked'] == true;
      if (mounted) {
        setState(() {
          _likesCount = likes ?? _likesCount;
          _hasLiked = liked;
        });
      }
    } catch (e) {
      debugPrint("Error toggling like: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRealVideoPlayer(),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
                  ),
                  10.verticalSpace,
                  Text(
                    widget.video.description,
                    style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                  ),
                  
                  24.verticalSpace,
                  
                  _buildStatsRow(),
                  
                  32.verticalSpace,
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Related Videos", style: AppTextStyles.bold16cairo),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          "View All",
                          style: AppTextStyles.bold16cairo.copyWith(color: const Color(0xFFC4D35D)),
                        ),
                      ),
                    ],
                  ),
                  12.verticalSpace,
                  _buildRelatedVideosList(),
                  20.verticalSpace,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        "Video Details",
        style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: AppColors.darkblack),
          onPressed: () {
            final fullUrl = _getVideoUrl(widget.video.videoUrl);
            SharePlus.instance.share(
              ShareParams(
                text: "Check out this educational video: ${widget.video.title}\n$fullUrl",
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRealVideoPlayer() {
    final double aspect = _isInitialized ? _controller.value.aspectRatio : 16 / 9;
    return AspectRatio(
      aspectRatio: aspect,
      child: Container(
        color: Colors.black,
        child: _isInitialized
            ? Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_controller),
                  Positioned.fill(
                    child: VideoControlsOverlay(
                      controller: _controller,
                      onFullScreenToggle: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullscreenVideoPlayer(controller: _controller),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(color: Color(0xFFC4D35D)),
              ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        GestureDetector(
          onTap: _toggleLike,
          child: _buildStatItem(
            _hasLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined, 
            "$_likesCount",
            isActive: _hasLiked,
          ),
        ),
        20.horizontalSpace,
        _buildStatItem(Icons.visibility_outlined, "$_viewsCount"),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String val, {bool isActive = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFE4ECD0) : AppColors.lightYellow.withOpacity(0.3), 
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20.sp,
              color: AppColors.lightYellow, 
            ),
          ),
          10.horizontalSpace,
          Text(
            val,
            style: AppTextStyles.bold16cairo.copyWith(
              color: const Color(0xFF2D3142), 
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedVideosList() {
    final related = widget.video.relatedVideos ?? [];
    if (related.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text("No related videos found", style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'))),
      );
    }
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: related.length,
        itemBuilder: (context, index) {
          final relVideo = related[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => VideoDetailsView(video: relVideo),
                ),
              );
            },
            child: Container(
              width: 180.w,
              margin: EdgeInsets.only(right: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: _buildRelatedThumbnail(relVideo.thumbnailUrl),
                  ),
                  8.verticalSpace,
                  Text(
                    relVideo.title,
                    style: AppTextStyles.bold16cairo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRelatedThumbnail(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        height: 100.h,
        width: 180.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], height: 100.h, width: 180.w, child: const Icon(Icons.broken_image)),
      );
    } else if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final fullUrl = 'http://10.238.1.136:5000$cleanPath';
      return Image.network(
        fullUrl,
        height: 100.h,
        width: 180.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], height: 100.h, width: 180.w, child: const Icon(Icons.broken_image)),
      );
    } else {
      return Image.asset(
        path,
        height: 100.h,
        width: 180.w,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[200], height: 100.h, width: 180.w, child: const Icon(Icons.broken_image)),
      );
    }
  }
}