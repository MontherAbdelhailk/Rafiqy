import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart'; // لو بتستخدمي screenutil

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showLogo;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showLogo = true, 
  });

  @override
  Widget build(BuildContext context) {
    return 
    Padding(
      padding: const EdgeInsets.all(10),
      child: AppBar(
        backgroundColor: AppColors.babypink,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title, 
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
        ),
        centerTitle: true,
        actions: actions ?? [
          if (showLogo)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: SvgPicture.asset(
                'assets/images/Group 4.svg',
                width: 56.w,
                height: 38.h,
              ),
            ),
        ],
      ),
    );
  }

  @override
  // ده الجزء المسؤول عن تحديد حجم الـ AppBar
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}