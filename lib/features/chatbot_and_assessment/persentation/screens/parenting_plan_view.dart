import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';
import '../../../../core/thieming/app_styles.dart';
import '../widgets/parenting_plan_card.dart';

class ParentingPlanView extends StatefulWidget {
  const ParentingPlanView({super.key});

  @override
  State<ParentingPlanView> createState() => _ParentingPlanViewState();
}

class _ParentingPlanViewState extends State<ParentingPlanView> {
  @override
  void initState() {
    super.initState();
    context.read<ParentingPlanCubit>().fetchPlan('temp_user_123');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
         Text("الخطه التربويه", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
                  ],
                ),
              ),
              
              Expanded(
                // 🌟 الحل السحري: بنفصل الـ Actions بتاعة الـ PDF جوه الـ Listener عشان متأثرش على الـ UI
                child: BlocConsumer<ParentingPlanCubit, ParentingPlanState>(
                  listener: (context, state) {
                    if (state is SavePdfLoading) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("جاري تحميل ملف الـ PDF..."), duration: Duration(seconds: 1)),
                      );
                    } else if (state is SavePdfSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم تحميل الملف بنجاح! 🎉")),
                      );
                    } else if (state is ParentingPlanError && state.message.contains("PDF")) {
                      // لو الأيرور خاص بالـ PDF نظهره هنا بس
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                      );
                    }
                  },
                  buildWhen: (previous, current) => 
                      current is ParentingPlanLoading || 
                      current is ParentingPlanSuccess || 
                      (current is ParentingPlanError && !current.message.contains("PDF")),
                  builder: (context, state) {
                    if (state is ParentingPlanLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ParentingPlanError) {
                      return Center(child: Text(state.message));
                    } else if (state is ParentingPlanSuccess) {
                      if (state.plans.isEmpty) {
                        return const Center(child: Text("لا توجد خطة تربوية حالياً"));
                      }
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: state.plans.length,
                        itemBuilder: (context, index) {
                          final plan = state.plans[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: ParentingPlanCard(
                              plan: plan,
                              onSavePdfPressed: () {
                                context.read<ParentingPlanCubit>().downloadPdf("temp_user_123");
                              },
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}