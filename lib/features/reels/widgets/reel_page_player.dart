import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';
import 'package:rafiq/features/reels/logic/reels_cubit.dart';
import 'package:rafiq/features/reels/models/reel_entity.dart';
import 'package:rafiq/features/reels/widgets/reels_user_info.dart';
import 'package:rafiq/features/reels/widgets/reels_slider.dart';
import 'package:rafiq/features/video/persentation/widgets/video_controls_overlay.dart';

class ReelPagePlayer extends StatefulWidget {
  final ReelEntity reel;
  final bool isActive;
  final bool isAdmin;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onAdminAction;

  const ReelPagePlayer({
    super.key,
    required this.reel,
    required this.isActive,
    required this.isAdmin,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onAdminAction,
  });

  @override
  State<ReelPagePlayer> createState() => _ReelPagePlayerState();
}

class _ReelPagePlayerState extends State<ReelPagePlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasIncrementedView = false;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    _initializePlayer();
  }

  void _initializePlayer() {
    final videoUrl = widget.reel.videoUrl;
    final Uri uri = Uri.parse(videoUrl);

    if (videoUrl.startsWith('http://') || videoUrl.startsWith('https://')) {
      _controller = VideoPlayerController.networkUrl(uri);
    } else {
      // Local path from backend server
      final cleanPath = videoUrl.startsWith('/') ? videoUrl : '/$videoUrl';
      final absoluteUrl = 'http://10.238.1.136:5000$cleanPath';
      _controller = VideoPlayerController.networkUrl(Uri.parse(absoluteUrl));
    }

    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        if (widget.isActive) {
          _controller!.play();
          _controller!.setLooping(true);
          _triggerViewIncrement();
        }
      }
    });
  }

  void _triggerViewIncrement() {
    if (!_hasIncrementedView) {
      _hasIncrementedView = true;
      context.read<ReelsCubit>().watchReel(widget.reel.id);
    }
  }

  @override
  void didUpdateWidget(covariant ReelPagePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;

    if (widget.isActive && !oldWidget.isActive) {
      // Swiped into view
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      _controller!.play();
      _controller!.setLooping(true);
      _triggerViewIncrement();
    } else if (!widget.isActive && oldWidget.isActive) {
      // Swiped out of view
      _controller!.pause();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video Player
        Positioned.fill(
          child: _isInitialized && _controller != null
              ? Stack(
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                    Positioned.fill(
                      child: VideoControlsOverlay(
                        controller: _controller!,
                      ),
                    ),
                  ],
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF1a1a2e),
                        const Color(0xFF16213e).withOpacity(0.9),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF96A53A)),
                  ),
                ),
        ),

        // Bottom dark gradient overlay
        Positioned.fill(
          child: IgnorePointer(
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
        ),

        // User info + caption
        Positioned(
          bottom: 80.h,
          left: 16.w,
          right: 80.w,
          child: ReelsUserInfo(
            userName: widget.reel.authorName.isNotEmpty ? widget.reel.authorName : 'Rafiq',
            description: widget.reel.caption,
            imageUrl: widget.reel.authorImage,
          ),
        ),

        // Side Action Bar
        Positioned(
          bottom: 80.h,
          right: 12.w,
          child: ReelsSidebarActions(
            isAdmin: widget.isAdmin,
            loveCount: widget.reel.loveCount,
            commentCount: widget.reel.commentCount,
            hasLoved: widget.reel.hasLoved,
            commentsEnabled: widget.reel.commentsEnabled,
            onLike: widget.onLike,
            onComment: widget.onComment,
            onShare: widget.onShare,
            onAdminAction: widget.onAdminAction,
          ),
        ),
      ],
    );
  }
}
