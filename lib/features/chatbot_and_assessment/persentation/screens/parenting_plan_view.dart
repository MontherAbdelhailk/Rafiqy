import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/utils/secure_storage.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/planning_state_cubit.dart';
import '../../../../core/thieming/app_styles.dart';
import '../widgets/parenting_plan_card.dart';

class ParentingPlanView extends StatefulWidget {
  final bool isFromAssessment;

  const ParentingPlanView({
    super.key,
    this.isFromAssessment = true,
  });

  @override
  State<ParentingPlanView> createState() => _ParentingPlanViewState();
}

class _ParentingPlanViewState extends State<ParentingPlanView> {


  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

Future<void> _loadUserId() async {
  userId = await SecureStorage.getUserId();

  if (!mounted) return;

  if (!widget.isFromAssessment && userId != null) {
    context.read<ParentingPlanCubit>().fetchPlan(userId!);
  }

  setState(() {});
} // <-- القوس ده كان ناقص

@override
Widget build(BuildContext context) {
      return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
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
                  Text("Parenting Plan", style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
                ],
              ),
            ),
            
            Expanded(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                    );
                  }
                  else if (state is GeneratePlanError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("فشل إنشاء الخطة: ${state.message}"), backgroundColor: Colors.red),
                    );
                  }
                },
                buildWhen: (previous, current) => 
                    current is ParentingPlanLoading || 
                    current is GeneratePlanLoading || 
                    current is ParentingPlanSuccess || 
                    current is GeneratePlanSuccess ||
                    (current is ParentingPlanError && !current.message.contains("PDF")) ||
                    current is GeneratePlanError,
                builder: (context, state) {
                  if (state is ParentingPlanLoading || state is GeneratePlanLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primaryNormal),
                          SizedBox(height: 16),
                          Text("جاري توليد خطتك التربوية الذكية بالذكاء الاصطناعي... 🌱", style: TextStyle(fontFamily: 'Cairo')),
                        ],
                      ),
                    );
                  } 
                  
                  else if (state is ParentingPlanError) {
                    return Center(child: Text(state.message));
                  } else if (state is GeneratePlanError) {
                    return Center(child: Text(state.message));
                  } 
                  
                  else if (state is ParentingPlanSuccess) {
                    if (state.plans.isEmpty) {
                      return const Center(child: Text("لا توجد خطة تربوية حالياً"));
                    }
                    
                    final plan = state.plans.first; 
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ParentingPlanCard(
                            plan: plan,
                            onSavePdfPressed: () {
if (userId != null) {
  context.read<ParentingPlanCubit>().downloadPdf(userId!);
}                            },
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    );
                  }
                  
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
