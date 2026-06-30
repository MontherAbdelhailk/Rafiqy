// features/chatbot_and_assessment/persentation/widgets/digital_wallet_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class DigitalWalletSection extends StatelessWidget {
  const DigitalWalletSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Digital Wallet', style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack)),
          SizedBox(height: 20.h),
          _walletButton('Apple Pay', Colors.black, Colors.white, Icons.apple),
          SizedBox(height: 12.h),
          _walletButton('Google Pay', Colors.white, Colors.black, Icons.golf_course_sharp, hasBorder: true),
        ],
      ),
    );
  }

  Widget _walletButton(String text, Color bg, Color textCol, IconData icon, {bool hasBorder = false}) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: hasBorder ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textCol, size: 20.sp),
          SizedBox(width: 8.w),
          Text(text, style: AppTextStyles.bold16cairo.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildFloatingCard({required Widget child}) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: child,
    );
  }
}