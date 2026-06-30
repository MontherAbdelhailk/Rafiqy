import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class CategoryVideoCardContent extends StatelessWidget {
  final String title;
  final String description;

  const CategoryVideoCardContent({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack)),
                4.verticalSpace,
                Text(description, style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey3)),
              ],
            ),
          ),
          _buildArrowIcon(),
        ],
      ),
    );
  }

  Widget _buildArrowIcon() {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F4E8),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.arrow_forward_ios, size: 14.sp, color: const Color(0xFF9DB454)),
    );
  }
}