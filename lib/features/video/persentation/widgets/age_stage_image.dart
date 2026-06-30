import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AgeStageImage extends StatelessWidget {
  final String imagePath;

  const AgeStageImage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.asset(
        imagePath,
        width: 100.w,
        height: 100.h,
        fit: BoxFit.cover,
      ),
    );
  }
}