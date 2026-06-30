// features/chatbot_and_assessment/persentation/screens/confirmation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart'; // افترضت وجوده عندك
import 'package:rafiq/features/book_session/persentation/widgets/session_details.dart';
import 'package:rafiq/features/book_session/persentation/widgets/zoom_meeting.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        title:  Text('Confirmation',style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            Center(
              child: Column(
                children: [
                     CircleAvatar(
                      radius: 40.r,
                      backgroundColor: AppColors.lightYellow.withOpacity(0.1),
                      child: Icon(
                        Icons.check_circle, color: AppColors.lightYellow, size: 40.sp),
                    ),
                
                  SizedBox(height: 24.h),
                  Text('Booking Confirmed', style: AppTextStyles.bold20cairo.copyWith(color: AppColors.grey2)),
                  SizedBox(height: 12.h),
                  Text(
                    'Your session has been successfully scheduled.\nCheck your email for the calendar invite.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey3, height: 1.5),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 40.h),
            
            const SessionDetailsCard(),
            
            SizedBox(height: 20.h),
            
            const ZoomMeetingCard(),
            
            SizedBox(height: 40.h),
            
            CustomButton(
              text: 'Join Session',
              onPressed: () {},
              height: 55.h,
              borderRadius: 15.r,
            ),
            SizedBox(height: 16.h),
            CustomButton(
              text: 'Back to Home',
              textColor: AppColors.primaryNormal,
              textstyle: AppTextStyles.regular16cairo,
              onPressed: () {},
              height: 55.h,
              borderRadius: 15.r,
              backgroundColor: Colors.transparent,
              borderSide:   BorderSide(color: AppColors.primaryNormalHover),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
  //   return SizedBox(
  //     width: double.infinity,
  //     height: 55.h,
  //     child: OutlinedButton(
  //       onPressed: onPressed,
  //       style: OutlinedButton.styleFrom(
  //         side: BorderSide(color: AppColors.grey.withOpacity(0.3)),
  //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
  //       ),
  //       child: Text(text, style: AppTextStyles.medium16.copyWith(color: AppColors.primaryColor)),
  //     ),
  //   );
  // }

}