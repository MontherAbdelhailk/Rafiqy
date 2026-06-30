import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class VideoControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final VoidCallback? onFullScreenToggle;
  final bool isFullScreen;

  const VideoControlsOverlay({
    super.key,
    required this.controller,
    this.onFullScreenToggle,
    this.isFullScreen = false,
  });

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _CustomProgressIndicator extends StatelessWidget {
  final VideoPlayerController controller;
  const _CustomProgressIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return VideoProgressIndicator(
      controller,
      allowScrubbing: true,
      colors: const VideoProgressColors(
        playedColor: Color(0xFFC4D35D),
        bufferedColor: Colors.white30,
        backgroundColor: Colors.white12,
      ),
    );
  }
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _visible = true;
  Timer? _hideTimer;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    _listener = () {
      if (mounted) setState(() {});
    };
    widget.controller.addListener(_listener);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_listener);
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  void _resetTimer() {
    setState(() {
      _visible = true;
    });
    _startHideTimer();
  }

  void _toggleControls() {
    setState(() {
      _visible = !_visible;
    });
    if (_visible) {
      _startHideTimer();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
      } else {
        widget.controller.play();
      }
    });
    _resetTimer();
  }

  void _seekForward() {
    final current = widget.controller.value.position;
    final max = widget.controller.value.duration;
    final target = current + const Duration(seconds: 10);
    widget.controller.seekTo(target > max ? max : target);
    _resetTimer();
  }

  void _seekBackward() {
    final current = widget.controller.value.position;
    const target = Duration(seconds: 10);
    widget.controller.seekTo(current > target ? current - target : Duration.zero);
    _resetTimer();
  }

  void _cycleSpeed() {
    final speeds = [0.5, 1.0, 1.5, 2.0];
    final current = widget.controller.value.playbackSpeed;
    int nextIdx = speeds.indexOf(current) + 1;
    if (nextIdx >= speeds.length || nextIdx < 0) {
      nextIdx = 0;
    }
    widget.controller.setPlaybackSpeed(speeds[nextIdx]);
    _resetTimer();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$minutes:$seconds";
    }
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.controller.value.position;
    // Extract actual duration directly from video player controller value.
    final duration = widget.controller.value.duration;

    return GestureDetector(
      onTap: _toggleControls,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_visible,
          child: Container(
            color: Colors.black38,
            child: Stack(
              children: [
                // Centered play, seek controls
                Align(
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.replay_10, color: Colors.white, size: 32.sp),
                        onPressed: _seekBackward,
                      ),
                      30.horizontalSpace,
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: CircleAvatar(
                          radius: 28.r,
                          backgroundColor: Colors.black45,
                          child: Icon(
                            widget.controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                            size: 36.sp,
                          ),
                        ),
                      ),
                      30.horizontalSpace,
                      IconButton(
                        icon: Icon(Icons.forward_10, color: Colors.white, size: 32.sp),
                        onPressed: _seekForward,
                      ),
                    ],
                  ),
                ),

                // Bottom control panel (Progress bar, timing, playback speed, fullscreen)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    color: Colors.black54,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Indicator
                        _CustomProgressIndicator(controller: widget.controller),
                        8.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Timing Display
                            Text(
                              "${_formatDuration(position)} / ${_formatDuration(duration)}",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontFamily: 'Cairo',
                              ),
                            ),

                            // Speed selection & Fullscreen buttons
                            Row(
                              children: [
                                TextButton(
                                  onPressed: _cycleSpeed,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    "${widget.controller.value.playbackSpeed}x",
                                    style: TextStyle(
                                      color: const Color(0xFFC4D35D),
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                ),
                                if (widget.onFullScreenToggle != null) ...[
                                  12.horizontalSpace,
                                  IconButton(
                                    icon: Icon(
                                      widget.isFullScreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: Colors.white,
                                      size: 24.sp,
                                    ),
                                    onPressed: widget.onFullScreenToggle,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
