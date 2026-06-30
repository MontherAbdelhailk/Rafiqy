// features/chatbot_and_assessment/persentation/widgets/session_details_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class SessionDetailsCard extends StatelessWidget {
  const SessionDetailsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SESSION DETAILS', style: AppTextStyles.bold20cairo.copyWith(color: AppColors.grey2)),
          SizedBox(height: 20.h),
          _buildDetailRow('Date', 'October 24, 2023'),
          SizedBox(height: 16.h),
          _buildDetailRow('Time', '10:00 AM - 11:00 AM'),
          SizedBox(height: 16.h),
          _buildDetailRow('Session Type', 'One-on-One Mentoring'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey3)),
        Text(value, style: AppTextStyles.regular12inter.copyWith(color: AppColors.grey2)),
      ],
    );
  }
}