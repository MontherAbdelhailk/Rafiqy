import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';

class AppTextFormField extends StatelessWidget {
  final String hintText;
  final TextStyle? hintStyle;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool? isObscureText;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final Color? backgroundColor;
  final TextInputType? keyboardType; 

  const AppTextFormField({
    super.key,
    required this.hintText,
    this.hintStyle,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.isObscureText,
    this.enabledBorder, // اختياري
    this.focusedBorder, // اختياري
    this.backgroundColor, // لو حابة تدي خلفية للحقل
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isObscureText ?? false,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        isDense: true, // بتخلي الـ padding أظبط
        filled: backgroundColor != null,
        fillColor: backgroundColor,
        hintText: hintText,
        hintStyle: hintStyle ?? TextStyle(color: AppColors.grey2, fontSize: 14.sp),
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        
        // لو باصيتي Border هيستخدمه، لو لأ هيستخدم الـ Underline القديم بتاعك
        enabledBorder: enabledBorder ?? const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brown),
        ),
        focusedBorder: focusedBorder ?? const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.brown),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}