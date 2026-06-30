import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/features/video/domain/entities/age_statge_entity.dart';
import 'package:rafiq/core/widgets/app_generic_card.dart';
import 'package:rafiq/features/video/persentation/widgets/age_statge_info.dart';
import 'age_stage_image.dart';

class AgeStageCard extends StatelessWidget {
  final AgeStageEntity stage;
  final VoidCallback onTap;

  const AgeStageCard({super.key, required this.stage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AppGenericCard(
        onTap: onTap,
        padding: 12.w,
        color: Colors.white,
        borderRadius: 16.r,
        shadow: BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        child: Row(
          children: [
            AgeStageInfoColumn(stage: stage),
            12.horizontalSpace,
            AgeStageImage(imagePath: stage.imagePath),
          ],
        ),
      ),
    );
  }
}