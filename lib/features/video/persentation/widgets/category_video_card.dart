import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart';
import 'category_video_card_content.dart';
import 'category_video_header.dart';

class CategoryVideoCard extends StatelessWidget {
  final String title;
  final String description;
  final String iconName;
  final VoidCallback onTap;

  const CategoryVideoCard({
    super.key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.onTap,
  });

  IconData _getIconData(String name) {
    switch (name.trim().toLowerCase()) {
      case 'family_restroom': 
      case 'parenting':
        return Icons.family_restroom;
      case 'favorite': 
      case 'marital':
        return Icons.favorite;
      case 'home_work': 
      case 'family_preparation':
        return Icons.home_work_sharp;
      default: 
        return Icons.video_library_rounded; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: AppGenericCard(
        onTap: onTap,
        height: 270.h,
        color: Colors.transparent,
        borderRadius: 8.r,
        border: Border.all(color: AppColors.lightYellow.withOpacity(0.2)),
        child: Column(
          children: [
            CategoryVideoCardHeader(icon: _getIconData(iconName)),
            CategoryVideoCardContent(
              title: title,
              description: description,
              backgroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}