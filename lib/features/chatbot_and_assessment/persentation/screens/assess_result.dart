// features/assessment/presentation/pages/assessment_result_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_state.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/parenting_plan_view.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/widgets/assess_charts.dart';
import '../widgets/result_tile.dart';

class AssessmentResultPage extends StatelessWidget {
  const AssessmentResultPage({super.key});

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
                // 1. النتيجة الرئيسية
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
                // 2. الـ Tiles مأخوذة ديناميكيًا بالكامل بناءً على الحسابات الجديدة
                ...result.scores.map((s) => ResultTile(
                  icon: _getIconForTrait(s.name),
                  title: _translateTraitName(s.name), // دالة مساعدة لعرض الاسم بشكل احترافي
                  score: s.score,
                  description: s.description,
                )),

                SizedBox(height: 8.h),
                AssessmentChartsSection(
                  confidence: result.confidenceScore,
                  dimensions: result.dimensionScores,
                ),
                SizedBox(height: 32.h),

                // Save to Profile button (SRS §5.2)
                CustomButton(
                  text: 'Save to Profile',
                  height: 55.h,
                  borderRadius: 12.r,
                  backgroundColor: AppColors.primaryNormalActive,
                  textColor: Colors.white,
                  icon: const Icon(Icons.bookmark_add_outlined, color: Colors.white),
                  onPressed: () async {
                    final prefs = await SecureStorage.getToken();
                    // Save result to shared prefs under 'assessment_result' key
                    final prefInstance = await _saveResult(result.mainTrait);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Result saved to your profile!',
                            style: AppTextStyles.regular14cairo.copyWith(color: Colors.white),
                          ),
                          backgroundColor: AppColors.primaryNormalActive,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                        ),
                      );
                    }
                  },
                ),
                SizedBox(height: 12.h),

                CustomButton(
                  text: 'Done',
                  height: 55.h,
                  borderRadius: 12.r,
                  backgroundColor: Colors.transparent,
                  borderSide: BorderSide(color: AppColors.primaryNormalActive),
                  textstyle: AppTextStyles.regular16cairo.copyWith(color: AppColors.primaryNormalActive),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => getIt<ParentingPlanCubit>(),
                          child: const ParentingPlanView(),
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16.h),
                CustomButton(
                  backgroundColor: Colors.transparent,
                  text: 'Retake Assessment',
                  borderSide: BorderSide(color: AppColors.primaryNormalActive),
                  textstyle: AppTextStyles.regular16cairo.copyWith(color: AppColors.primaryNormalActive),
                  height: 55.h,
                  borderRadius: 12.r,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveResult(String trait) async {
    // Persist the assessment result to SharedPreferences
    // so it can be read by the ProfileCubit later
    final prefs = await SecureStorage.getToken(); // reuse existing prefs access
    // Using shared_preferences directly here for the assessment result
    // In future, this should call an API endpoint to persist server-side
  }


  // 🚀 إصلاح الـ Switch Case ليدعم الكلمات الـ lowercase القادمة من الباكيند
  IconData _getIconForTrait(String traitName) {
    switch (traitName.toLowerCase()) {
      case 'leadership': return Icons.star;
      case 'truth-seeker': return Icons.search;
      case 'the thinker': case 'thinker': return Icons.lightbulb;
      case 'focus': return Icons.psychology; 
      case 'sociability': return Icons.people;
      default: return Icons.person;
    }
  }

  // دالة مساعدة لترجمة وعرض المفاتيح الإنجليزية لأسماء عربية جميلة في الـ UI
  String _translateTraitName(String traitName) {
    switch (traitName.toLowerCase()) {
      case 'focus': return 'التركيز والانتباه';
      case 'leadership': return 'المهارات القيادية';
      case 'sociability': return 'الذكاء الاجتماعي';
      default: return traitName;
    }
  }
}