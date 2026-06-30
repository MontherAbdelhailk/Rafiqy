// lib/features/booking/presentation/screens/payment_result_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'my_sessions_screen.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String bookingId;
  final double amount;

  const PaymentResultScreen({
    super.key,
    required this.isSuccess,
    required this.bookingId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Icon Status
              Container(
                width: 100.w,
                height: 100.w,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.primaryLight
                      : const Color(0xFFFFECEF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 64.sp,
                  color: isSuccess ? AppColors.primaryNormal : AppColors.errorNormal,
                ),
              ),
              SizedBox(height: 32.h),

              // Title & Message
              Text(
                isSuccess ? 'Payment Successful!' : 'Payment Failed',
                style: AppTextStyles.bold24cairo.copyWith(
                  color: isSuccess ? AppColors.primaryDarkActive : AppColors.errorNormal,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                isSuccess
                    ? 'Your consultation session has been booked successfully. You can now view and join your sessions.'
                    : 'We could not process your payment. Any reserved slots have been released. Please try booking again.',
                textAlign: TextAlign.center,
                style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8, height: 1.5),
              ),
              SizedBox(height: 40.h),

              // Booking details card
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      _buildRow('Booking ID', '#${bookingId.substring(0, 8).toUpperCase()}'),
                      const Divider(height: 24),
                      _buildRow('Amount Paid', '${amount.toStringAsFixed(2)} EGP'),
                      const Divider(height: 24),
                      _buildRow('Status', isSuccess ? 'Confirmed' : 'Unpaid', 
                          valueColor: isSuccess ? AppColors.primaryNormal : AppColors.errorNormal),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // CTAs
              if (isSuccess) ...[
                 CustomButton(
                  text: 'View My Sessions',
                  height: 55.h,
                  borderRadius: 15.r,
                  onPressed: () {
                    // Clear the booking flow stack and navigate to Sessions Screen
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MySessionsScreen()),
                      (route) => route.isFirst,
                    );
                  },
                ),
                SizedBox(height: 16.h),
                OutlinedButton(
                  onPressed: () {
                    // Navigate back to the home screen
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55.h),
                    side: BorderSide(color: AppColors.primaryNormal, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.r),
                    ),
                  ),
                  child: Text(
                    'Back to Home',
                    style: AppTextStyles.bold16cairo.copyWith(color: AppColors.primaryNormal),
                  ),
                ),
              ] else ...[
                CustomButton(
                  text: 'Try Booking Again',
                  height: 55.h,
                  borderRadius: 15.r,
                  onPressed: () {
                    // Pop back directly to the date/slots selection screen
                    Navigator.popUntil(context, ModalRoute.withName('select_date'));
                  },
                ),
                SizedBox(height: 16.h),
                TextButton(
                  onPressed: () {
                    // Pop to home
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: Text(
                    'Cancel and Go Home',
                    style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1),
        ),
        Text(
          value,
          style: AppTextStyles.bold14cairo.copyWith(color: valueColor ?? AppColors.darkblack),
        ),
      ],
    );
  }
}
