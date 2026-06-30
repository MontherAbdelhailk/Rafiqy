import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart';
import 'package:rafiq/features/reels/widgets/reels_user_info.dart';
import 'package:rafiq/features/reels/logic/reels_cubit.dart';
import 'package:rafiq/features/reels/logic/reels_state.dart';
import 'package:rafiq/features/reels/models/reel_entity.dart';
import 'package:rafiq/features/reels/widgets/reel_page_player.dart';
import 'package:rafiq/features/reels/widgets/reels_comments_sheet.dart';

/// Full-screen vertical Shorts feed (SRS §3.4)
/// - Swipe up/down navigation
/// - Auto-play per page
/// - Love + Comment overlays
/// - Upload button visible only for admins
class ReelsView extends StatefulWidget {
  final bool isAdmin;
  final XFile? videoFile;

  const ReelsView({super.key, this.isAdmin = false, this.videoFile});

  @override
  State<ReelsView> createState() => _ReelsViewState();
}

class _ReelsViewState extends State<ReelsView> {
  VideoPlayerController? _controller;
  bool _isAdmin = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAdminRole();
    if (widget.videoFile != null) {
      _initVideo(widget.videoFile!.path);
    }
  }

  Future<void> _checkAdminRole() async {
    final isAdmin = await SecureStorage.isAdmin();
    if (mounted) setState(() => _isAdmin = isAdmin || widget.isAdmin);
  }

  void _initVideo(String path) {
    _controller?.dispose();
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      _controller = VideoPlayerController.file(File(path));
    }
    _controller!.initialize().then((_) {
      if (mounted) setState(() {});
      _controller!.setLooping(true);
      _controller!.play();
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.videoFile != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildLocalReelPage(),
            _buildHeader(context),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<ReelsCubit, ReelsState>(
        buildWhen: (previous, current) =>
            current is ReelsLoading || current is ReelsLoaded || current is ReelsError,
        builder: (context, state) {
          if (state is ReelsLoading) {
            return Stack(
              children: [
                const Center(child: CircularProgressIndicator(color: Color(0xFF96A53A))),
                _buildHeader(context),
              ],
            );
          } else if (state is ReelsLoaded) {
            final reels = state.reels;
            if (reels.isEmpty) {
              return Stack(
                children: [
                  const Center(
                    child: Text(
                      "No reels found.",
                      style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                    ),
                  ),
                  _buildHeader(context),
                ],
              );
            }
            return Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    if (index >= reels.length - 2) {
                      context.read<ReelsCubit>().loadReels();
                    }
                  },
                  itemBuilder: (context, index) {
                    final reel = reels[index];
                    return ReelPagePlayer(
                      reel: reel,
                      isActive: index == _currentIndex,
                      isAdmin: _isAdmin,
                      onLike: () {
                        context.read<ReelsCubit>().toggleLoveReel(reel.id);
                      },
                      onComment: () {
                        _showCommentSheet(context, reel);
                      },
                      onShare: () {
                        String fullUrl = reel.videoUrl;
                        if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
                          final cleanPath = fullUrl.startsWith('/') ? fullUrl : '/$fullUrl';
                          fullUrl = 'http://10.0.2.2:5000$cleanPath';
                        }
                        SharePlus.instance.share(
                          ShareParams(
                            text: "Check out this reel: ${reel.caption}\n$fullUrl",
                          ),
                        );
                      },
                      onAdminAction: () {
                        if (_isAdmin) {
                          _showAdminOptions(context, reel);
                        }
                      },
                    );
                  },
                ),
                _buildHeader(context),
              ],
            );
          } else if (state is ReelsError) {
            return Stack(
              children: [
                Center(
                  child: Text(
                    "Error: ${state.message}",
                    style: const TextStyle(color: Colors.red, fontFamily: 'Cairo'),
                  ),
                ),
                _buildHeader(context),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLocalReelPage() {
    return Stack(
      children: [
        if (_controller != null && _controller!.value.isInitialized)
          Center(
            child: AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: Color(0xFF96A53A))),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 80.h,
          left: 16.w,
          right: 80.w,
          child: const ReelsUserInfo(
            userName: "Rafiq",
            description: "Local Video Preview",
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 8.h,
      left: 12.w,
      right: 12.w,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 26.sp),
          ),
          Text(
            "Shorts",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
          ),
          // Admin-only upload button (SRS §3.4 — users cannot upload)
          if (_isAdmin)
            IconButton(
              onPressed: () => context.push(AppRouter.uploadMediaView),
              icon: Icon(Icons.add_circle_outline, color: Colors.white, size: 26.sp),
            )
          else
            SizedBox(width: 48.w),
        ],
      ),
    );
  }

  void _showCommentSheet(BuildContext context, ReelEntity reel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<ReelsCubit>(),
        child: ReelsCommentsSheet(reelId: reel.id),
      ),
    );
  }

  void _showAdminOptions(BuildContext context, ReelEntity reel) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Delete Reel", style: TextStyle(fontFamily: 'Cairo')),
        content: const Text("Are you sure you want to delete this reel permanently?", style: TextStyle(fontFamily: 'Cairo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel", style: TextStyle(fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ReelsCubit>().deleteReel(reel.id);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}