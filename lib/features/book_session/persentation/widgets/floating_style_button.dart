// features/chatbot_and_assessment/persentation/widgets/booking_slot_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class BookingSlotTile extends StatelessWidget {
  final String day;
  final String time;
  final bool isSelected;
  final VoidCallback onTap;

  const BookingSlotTile({
    super.key,
    required this.day,
    required this.time,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100.w,
        margin: EdgeInsets.only(right: 12.w, bottom: 10.h, top: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFEFCE8) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ?AppColors.lightYellow.withOpacity(0.5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.15 : 0.05),
              blurRadius: 10,
              offset: isSelected ? const Offset(0, 5) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(day, style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey9)),
            SizedBox(height: 4.h),
            Text(time, style:AppTextStyles.bold14cairo.copyWith(color: AppColors.darkblack)),
          ],
        ),
      ),
    );
  }
}