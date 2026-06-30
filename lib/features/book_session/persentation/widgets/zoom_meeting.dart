// features/chatbot_and_assessment/persentation/widgets/zoom_meeting_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';

class ZoomMeetingCard extends StatelessWidget {
  const ZoomMeetingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5E9), 
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.lightYellow.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(Icons.videocam_outlined, color: AppColors.lightYellow, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Text('Zoom Meeting', style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey2)),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Your Zoom meeting link has been sent to you',
            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
          ),
          SizedBox(height: 16.h),


          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: AppColors.lightYellow, size: 16.sp),
                  SizedBox(width: 8.w),
                  Text('Copy Link', style: AppTextStyles.bold14cairo.copyWith(color: AppColors.lightYellow)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}