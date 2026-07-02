import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/features/video/domain/entities/age_statge_entity.dart';
import 'package:rafiq/features/video/persentation/video_list_view.dart';
import 'package:rafiq/features/video/persentation/widgets/ages_stage_card.dart';

/// categoryType: 'parenting' | 'marital' | 'family'
class AgeStagesView extends StatelessWidget {
  final String categoryType;

  const AgeStagesView({super.key, this.categoryType = 'parenting'});

  @override
  Widget build(BuildContext context) {
    final stages = _getStages();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            20.verticalSpace,
            Text(
              _getSubtitle(),
              style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
            ),
            8.verticalSpace,
            Text(
              _getDescription(),
              style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
            ),
            24.verticalSpace,
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stages.length,
              itemBuilder: (context, index) {
                return AgeStageCard(
                  stage: stages[index],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideosListView(
                        stageTitle: stages[index].title,
                      ),
                    ),
                  ),
                );
              },
            ),
            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    switch (categoryType) {
      case 'marital':
        return 'Marital Relationships';
      case 'family':
        return 'Youth (21–30)';
      default:
        return 'Parenting';
    }
  }

  String _getSubtitle() {
    switch (categoryType) {
      case 'marital':
        return 'Guidance for every stage of marriage';
      case 'family':
        return 'Youth (21–30)';
      default:
        return 'Parenting Age Stages for Rafiq';
    }
  }

  String _getDescription() {
    switch (categoryType) {
      case 'marital':
        return 'Educational videos on navigating relationship challenges.';
      case 'family':
        return 'Focused on preparing young adults for marriage and family life.';
      default:
        return 'Guided milestones for every developmental phase.';
    }
  }

  List<AgeStageEntity> _getStages() {
    switch (categoryType) {
      case 'marital':
        return [
          AgeStageEntity(
            ageRange: '',
            title: 'Before Divorce',
            description: 'Strategies for resolving conflict and strengthening the marital bond.',
            imagePath: 'assets/images/relation.png',
            subTitle: 'Relationship Management',
          ),
          AgeStageEntity(
            ageRange: '',
            title: 'After Divorce',
            description: 'Healing, co-parenting, and rebuilding a fulfilling life.',
            imagePath: 'assets/images/sons.png',
            subTitle: 'Recovery & Growth',
          ),
          AgeStageEntity(
            ageRange: '',
            title: 'Youth (21–30)',
            description:
                'Educational videos focused on preparing young adults for marriage, responsibility, and family life.',
            imagePath: 'assets/images/family_pic.png',
            subTitle: 'Young Adults',
          ),
        ];

      case 'family':
        return [
          AgeStageEntity(
            ageRange: '21–30 YEARS',
            title: 'Youth (21–30)',
            description:
                'Preparing young adults emotionally and practically for marriage and parenthood.',
            imagePath: 'assets/images/family_pic.png',
            subTitle: 'Young Adults',
          ),
        ];

      default: // 'parenting'
        return [
          AgeStageEntity(
            ageRange: '0–3 YEARS',
            title: 'Early Foundation',
            description: 'Focus on secure attachment and sensory development.',
            imagePath: 'assets/images/0to3.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '3–6 YEARS',
            title: 'Behavior Control',
            description: 'Establishing boundaries and fundamental social skills.',
            imagePath: 'assets/images/3to6.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '6–9 YEARS',
            title: 'Middle Childhood',
            description: 'Developing competence and school-age independence.',
            imagePath: 'assets/images/6to12.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '9–12 YEARS',
            title: 'Pre-Adolescence',
            description: 'Emotional changes and complex social structures.',
            imagePath: 'assets/images/12to15.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '12–15 YEARS',
            title: 'Early Adolescence',
            description: 'Identity formation and navigating peer pressure.',
            imagePath: 'assets/images/12to15.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '15–18 YEARS',
            title: 'Late Adolescence',
            description: 'Preparing for autonomy and future planning.',
            imagePath: 'assets/images/15to18.png',
            subTitle: '',
          ),
          AgeStageEntity(
            ageRange: '18–21 YEARS',
            title: 'Transition to Maturity',
            description: 'Bridging adolescence and independent adult life.',
            imagePath: 'assets/images/18to21.png',
            subTitle: '',
          ),
        ];
    }
  }
}