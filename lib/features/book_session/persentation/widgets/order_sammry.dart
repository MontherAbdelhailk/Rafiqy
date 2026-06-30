// features/chatbot_and_assessment/persentation/widgets/order_summary_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.lightYellow.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', '\$42.00'),
          SizedBox(height: 8.h),
          _summaryRow('Delivery Fee', '\$2.50'),
          const Divider(height: 30),
          _summaryRow('Total Amount', '\$44.50', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal?  AppColors.darkblack:AppColors.grey8, fontSize: isTotal ? 18.sp : 16.sp, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(color: isTotal?  AppColors.darkblack:AppColors.grey8,fontSize: isTotal ? 18.sp : 16.sp, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}