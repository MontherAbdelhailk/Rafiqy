import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavBarItem(
            index: 0, 
            iconPath: "assets/images/home.svg", 
            label: "Home",
          ),
          _buildNavBarItem(
            index: 1,   
            iconPath: "assets/images/video.svg", 
            label: "Videos",
          ),
          _buildNavBarItem(
            index: 2,   
            iconPath: "assets/images/chatbot.svg", 
            label: "Chat",
          ),
          _buildNavBarItem(
            index: 3,   
            iconPath: "assets/images/reel.svg", 
            label: "Reels",
          ),
          _buildNavBarItem(
            index: 4,   
            iconData: Icons.calendar_today_outlined, 
            label: "Booking",
          ),
          _buildNavBarItem(
            index: 5,   
            iconPath: "assets/images/profile.svg", 
            label: "Profile",
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarItem({
    required int index, 
    String? iconPath, 
    IconData? iconData,
    required String label,
  }) {
    bool isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLightActive : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, 
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 24.sp, 
                height: 24.sp,
                colorFilter: ColorFilter.mode(
                  AppColors.primarDark, 
                  BlendMode.srcIn,
                ),
              )
            else if (iconData != null)
              Icon(
                iconData,
                size: 24.sp,
                color: AppColors.primarDark,
              ),
            if (isSelected) ...[
              8.horizontalSpace,
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primarDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}