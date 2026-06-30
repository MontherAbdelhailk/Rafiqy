// features/chatbot_and_assessment/persentation/widgets/credit_card_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'payment_text_field.dart';

class CreditCardSection extends StatelessWidget {
  const CreditCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildFloatingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Credit / Debit Card', style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack)),
          SizedBox(height: 20.h),
           PaymentTextField(label: 'Card number',  hintstyle: AppTextStyles.regular12inter.copyWith(color: AppColors.grey10), style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey8), 
           
           hint: '0000 0000 0000 0000', suffixIcon: Icon(Icons.credit_card)),
          SizedBox(height: 16.h),
          Row(
            children: [
               Expanded(child: PaymentTextField(label: 'Expiry Date',hintstyle: AppTextStyles.regular12inter.copyWith(color: AppColors.grey10), style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack), hint: 'MM/YY')),
              SizedBox(width: 16.w),
               Expanded(child: PaymentTextField(label: 'CVV', hint: '123', hintstyle: AppTextStyles.regular12inter.copyWith(color: AppColors.grey10), style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack))),
            ],
          ),
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