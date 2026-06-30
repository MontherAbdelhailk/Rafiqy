// features/chatbot_and_assessment/persentation/widgets/payment_text_field.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class PaymentTextField extends StatelessWidget {
  final String label;
  final String hint;
  final Widget? suffixIcon;

  final TextStyle? style;
  final TextStyle? hintstyle;

  const PaymentTextField({super.key, required this.label, required this.hint, this.hintstyle, this.suffixIcon, this.style});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: const Color(0xff4A5568))),
        SizedBox(height: 8.h),
        TextField(
          decoration: InputDecoration(
            labelStyle: style,
            hintText: hint,
            hintStyle: hintstyle,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.grey11,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
        ),
      ],
    );
  }
}