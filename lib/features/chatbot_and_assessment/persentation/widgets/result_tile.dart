import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class ResultTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int score;
  final String description;

  const ResultTile({
    super.key,
    required this.icon,
    required this.title,
    required this.score,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              color: AppColors.lightYellow.withOpacity(0.3),
            ),
            child: Icon(icon, color: const Color(0xffB6C93B), size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title, 
                      style: AppTextStyles.bold16cairo.copyWith(color: AppColors.grey2),
                    ),
                    SizedBox(width: 6.w), // مسافة صغيرة تفصل القوسين عن الكلمة
                    Text(
                      '($score%)', 
                      style: TextStyle(
                        fontSize: 16.sp, 
                        fontWeight: FontWeight.bold, 
                        color: AppColors.grey2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  description,  
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}