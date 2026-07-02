import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assessment_intro.dart'; 
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_state.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/parenting_plan_view.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/widgets/assess_charts.dart'; 
import '../widgets/result_tile.dart';

class AssessmentResultPage extends StatelessWidget {
  final String userId;
  
  const AssessmentResultPage({super.key, required this.userId });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text('Assessment Result', style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)), 
        centerTitle: true, 
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: BlocBuilder<AssessmentResultCubit, AssessmentResultState>(
        builder: (context, state) {
          if (state.status == AssessmentResultStatus.loading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xffB6C93B)));
          }
          
          if (state.result == null) {
            return const Center(child: Text("Results not available."));
          }

          final result = state.result!;
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, 
              children: [
                Text(
                  'Your Child is a ${result.mainTrait}', 
                  textAlign: TextAlign.center, 
                  style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
                ),
                SizedBox(height: 12.h),
                Text(
                  result.description, 
                  textAlign: TextAlign.center, 
                  style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8)
                ),
                
                SizedBox(height: 16.h),
                
                ...result.scores.take(4).map((s) => ResultTile(
                  icon: _getIconForTrait(s.name),
                  title: _translateTraitName(s.name), 
                  score: s.score,
                  description: s.description,
                )),

                SizedBox(height: 8.h),
                AssessmentChartsSection(
                  confidence: result.confidenceScore,
                  dimensions: result.dimensionScores,
                ),
                SizedBox(height: 32.h), 

                // 1. زرار Done شغال تمام
                CustomButton(
                  backgroundColor: AppColors.primaryNormalHover,
                  text: 'Done',
                  height: 55.h,
                  borderRadius: 12.r,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
create: (context) =>
    getIt<ParentingPlanCubit>()..generateAndFetchPlan(userId),
child: const ParentingPlanView(
  isFromAssessment: true,
),                      ),
                    ),  
                    );                 
                  },
                ),
                SizedBox(height: 16.h),
                
                CustomButton(
                
                  backgroundColor: Colors.transparent,
                  text: 'Retake Assessment',
                  borderSide: const BorderSide(color: AppColors.primaryNormalActive),
                  textstyle: AppTextStyles.regular16cairo.copyWith(color: AppColors.primaryNormal),
                  textColor: AppColors.primaryNormal,
                  height: 55.h,
                  borderRadius: 12.r,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssessmentIntroPage(
                        ),
                      ),
                    );
                  },
                ),
              ], 
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForTrait(String traitName) {
    switch (traitName.toLowerCase()) {
      case 'leadership': return Icons.star;
      case 'truth-seeker': return Icons.search;
      case 'the thinker': case 'thinker': return Icons.lightbulb;
      case 'focus': return Icons.psychology; 
      case 'sociability': return Icons.people;
      case 'empathy': return Icons.favorite;
      case 'self_control': return Icons.gavel;
      case 'curiosity': return Icons.search;
      case 'adaptability': return Icons.cached;
      case 'sensitivity': return Icons.waves;
      default: return Icons.person;
    }
  }

  String _translateTraitName(String traitName) {
    switch (traitName.toLowerCase()) {
      case 'focus': return 'Focus';
      case 'leadership': return 'Leadership';
      case 'sociability': return 'Sociability';
      case 'empathy': return 'Empathy';
      case 'self_control': return 'Self-Control';
      case 'curiosity': return 'Curiosity';
      case 'adaptability': return 'Adaptability';
      case 'sensitivity': return 'Sensitivity';
      default: 
        if (traitName.isEmpty) return traitName;
        return traitName[0].toUpperCase() + traitName.substring(1).toLowerCase();
    }
  }
}