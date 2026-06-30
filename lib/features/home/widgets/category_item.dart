import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart';

class CategoryItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback? onTap;

  const CategoryItem({
    super.key,
    required this.title,
    required this.imagePath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AppGenericCard(
            width: 100.w,
            height: 100.h,
            color: Colors.white,
            borderRadius: 16.r,
            shadow: BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            child: Center(
              child: Container(
                width: 70.w,
                height: 70.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(
                    color: AppColors.primaryNormal.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          12.verticalSpace,
          Text(
            title,
            style: AppTextStyles.bold16cairo,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}