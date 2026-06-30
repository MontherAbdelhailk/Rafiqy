// features/assessment/presentation/pages/assessment_questionnaire_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assess_result.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_state.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/parenting_plan_view.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/widgets/assess_option_card.dart';

class AssessmentQuestionnairePage extends StatelessWidget {
  final String userId;
  final int childAge;

  const AssessmentQuestionnairePage({
    super.key,
    required this.userId,
    required this.childAge,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AssessmentCubit>()..loadQuestions(), 
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 56.h,
          title: Center(
            child: BlocBuilder<AssessmentCubit, AssessmentState>(
              builder: (context, state) {
                final currentIdx = state.questions.isEmpty ? 0 : state.currentQuestionIndex + 1;
                return Text(
                  'Question $currentIdx of ${state.questions.length}', 
                  style: AppTextStyles.bold24cairo.copyWith(
                    color: AppColors.darkblack,
                    fontSize: 24.sp,
                  ),
                );
              },
            ),
          ),
        ),
        body: BlocBuilder<AssessmentCubit, AssessmentState>(
          builder: (context, state) {
            if (state.status == AssessmentStatus.loading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.lightYellow));
            }
            if (state.status == AssessmentStatus.error) {
              return const Center(child: Text("Error loading questions. Please check server."));
            }
            if (state.currentQuestion == null || state.questions.isEmpty) {
              return const Center(child: Text("No Questions Found"));
            }

            // 🌟 استخدام الـ CustomScrollView لحل الـ Overflow نهائياً وجعل الشاشة Scrollable
            return CustomScrollView(
              physics: const BouncingScrollPhysics(), // سكرول ناعم ومنعش للمستخدم
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false, // بيسمح للـ Spacer إنه يشتغل لو مفيش سكرول
                  child: Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Assessment Progress", 
                          style: AppTextStyles.bold16cairo.copyWith(
                            color: AppColors.grey8,
                            fontSize: 16.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        LinearProgressIndicator(
                          borderRadius: BorderRadius.circular(10.r),
                          minHeight: 10.h,
                          value: state.progress, 
                          color: AppColors.lightYellow, 
                          backgroundColor: AppColors.primaryLightActive,
                        ),
                        SizedBox(height: 30.h),
                        Container(
                          width: double.infinity,
                          alignment: Alignment.center,
                          child: Text(
                            state.currentQuestion!.questionText, 
                            textAlign: TextAlign.center, 
                            style: AppTextStyles.bold24inter.copyWith(
                              color: AppColors.darkblack,
                              fontSize: 24.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 30.h),
                        ...state.currentQuestion!.options.map((opt) => Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: OptionCard(
                            text: opt,
                            isSelected: state.currentQuestion!.selectedAnswer == opt,
                            onTap: () => context.read<AssessmentCubit>().selectAnswer(opt),
                          ),
                        )),
                        
                        // 🌟 الـ Spacer هيفضل يحافظ على مكانه في الشاشات الكبيرة، وهيتحول لـ مسافة مرنة تمنع الـ Overflow تلقائياً في الشاشات الصغيرة
                        const Spacer(),
                        SizedBox(height: 20.h), // مسافة أمان صغيرة فوق الزرار أثناء الـ Scroll

                        CustomButton(
                          text: state.isLastQuestion ? 'Finish' : 'Next',
                          height: 50.h,
                          borderRadius: 10.r,
                          onPressed: state.currentQuestion!.selectedAnswer != null
                              ? () async {
                                  if (state.isLastQuestion) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.lightYellow)),
                                    );

                                    bool success = await context.read<AssessmentCubit>().sendFinalAssessment(userId, childAge);
                                    
                                    if (context.mounted) Navigator.pop(context);

                                    if (success) {
                                      if (context.mounted) {
                                        Navigator.pushReplacement(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => MultiBlocProvider(
                                              providers: [
                                                BlocProvider(
                                                  create: (context) => getIt<AssessmentResultCubit>()..loadResults(
                                                    userId: userId,
                                                    childAge: childAge,
                                                    answeredQuestions: state.questions,
                                                  ),
                                                ),
                                                BlocProvider(
                                                  create: (context) => getIt<ParentingPlanCubit>(),
                                                ),
                                              ],
                                              child: const AssessmentResultPage(),
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Failed to submit assessment to server.")),
                                        );
                                      }
                                    }
                                  } else {
                                    context.read<AssessmentCubit>().nextQuestion();
                                  }
                                }
                              : null,
                          backgroundColor: state.currentQuestion!.selectedAnswer != null
                              ? const Color(0xffB6C93B)
                              : Colors.grey[300],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}