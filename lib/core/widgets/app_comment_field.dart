import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/widgets/apptextformfield.dart';


import 'package:rafiq/core/widgets/app_avatar.dart';

class AppCommentInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final String? Function(String?)? validator;
  final String? userImage;

  const AppCommentInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.validator,
    this.userImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.w, 
        right: 16.w, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 16.h, // لرفع الحقل مع الكيبورد
        top: 10.h
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            imageUrl: userImage,
            radius: 20.r,
          ),
          12.horizontalSpace,
          Expanded(
            child: AppTextFormField(
              controller: controller,
              hintText: "Write a comment...",
              validator: validator ?? (value) => null, // Default validator
              backgroundColor: const Color(0xFFF1F4F7),
              // بنعدل الـ Border هنا عشان يبقى Round زي الكومنتات
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25.r),
                borderSide: const BorderSide(color: Color(0xFF96A53A)),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.send_rounded, color: Color(0xFF96A53A)),
                onPressed: onSend,
              ),
            ),
          ),
        ],
      ),
    );
  }
}