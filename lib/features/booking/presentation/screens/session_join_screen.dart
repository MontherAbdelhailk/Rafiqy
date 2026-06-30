// lib/features/booking/presentation/screens/session_join_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';

class SessionJoinScreen extends StatefulWidget {
  final String sessionId;
  final String jitsiRoomName;
  final String jitsiUrl;
  final bool isAdmin;

  const SessionJoinScreen({
    super.key,
    required this.sessionId,
    required this.jitsiRoomName,
    required this.jitsiUrl,
    required this.isAdmin,
  });

  @override
  State<SessionJoinScreen> createState() => _SessionJoinScreenState();
}

class _SessionJoinScreenState extends State<SessionJoinScreen> {
  final _jitsiMeet = JitsiMeet();
  bool _isLaunching = false;

  Future<void> _joinMeeting() async {
    setState(() {
      _isLaunching = true;
    });

    try {
      final room = widget.jitsiRoomName;
      final serverUrl = widget.jitsiUrl.contains('//') 
          ? widget.jitsiUrl.split('/')[2] 
          : 'meet.jit.si';

      debugPrint("Joining Jitsi Room: $room on server: $serverUrl");

      final options = JitsiMeetConferenceOptions(
        serverURL: "https://$serverUrl",
        room: room,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "prejoinPageEnabled": false,
        },
        featureFlags: {
          "unsecuredRoom.warning.enabled": false,
          "welcomepage.enabled": false,
          "help.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: widget.isAdmin ? "Rafiq Doctor / Specialist" : "Rafiq Parent",
        ),
      );

      await _jitsiMeet.join(options);
    } catch (e) {
      debugPrint("Jitsi launch error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to launch video session: ${e.toString()}"),
          backgroundColor: AppColors.errorNormal,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Video Lobby',
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Video Lobby Illustration
              Container(
                width: 140.w,
                height: 140.w,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.videocam_rounded,
                  size: 80.sp,
                  color: AppColors.primaryNormal,
                ),
              ),
              SizedBox(height: 32.h),

              Text(
                'Ready to Join?',
                style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
              ),
              SizedBox(height: 12.h),
              Text(
                'Your secure video consultation room is ready. Please ensure your microphone and camera permissions are enabled.',
                textAlign: TextAlign.center,
                style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8, height: 1.5),
              ),
              SizedBox(height: 40.h),

              // Checklist
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      _buildChecklistRow(Icons.wifi, 'Stably connected to Wi-Fi or cellular data'),
                      const Divider(height: 24),
                      _buildChecklistRow(Icons.volume_up, 'Audio and microphone are enabled'),
                      const Divider(height: 24),
                      _buildChecklistRow(Icons.lock, 'Call is securely encrypted by Jitsi Meet'),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Join Call Button
              CustomButton(
                text: _isLaunching ? 'Connecting...' : 'Join Video Call',
                height: 55.h,
                borderRadius: 15.r,
                onPressed: _isLaunching ? null : _joinMeeting,
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Go Back',
                  style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.primaryNormal),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey4),
          ),
        ),
      ],
    );
  }
}
