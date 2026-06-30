import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CategoryVideoCardHeader extends StatelessWidget {
  final IconData icon;

  const CategoryVideoCardHeader({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4E8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
      ),
      child: Center(
        child: Icon(
          icon, 
          size: 40.sp, 
          color: const Color(0xFF9DB454),
        ),
      ),
    );
  }
}