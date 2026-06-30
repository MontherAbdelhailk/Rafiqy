import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/domain/entities/age_statge_entity.dart';

class AgeStageInfoColumn extends StatelessWidget {
  final AgeStageEntity stage;

  const AgeStageInfoColumn({super.key, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stage.ageRange,
            style: AppTextStyles.bold14cairo.copyWith(color: AppColors.primaryNormal),
          ),
          4.verticalSpace,
          Text(
            stage.title,
            style: AppTextStyles.bold20cairo.copyWith(color: AppColors.secondaryNormal),
          ),
          8.verticalSpace,
          Text(
            stage.description,
            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}