import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/parenting_plan.dart';
import '../../../../core/thieming/app_styles.dart';
import '../../../../core/widgets/app_generic_card.dart';

class ParentingPlanCard extends StatelessWidget {
  final ParentingPlanEntity plan;
  final VoidCallback onSavePdfPressed;

  const ParentingPlanCard({
    super.key,
    required this.plan,
    required this.onSavePdfPressed,
  });

  @override
  Widget build(BuildContext context) {
    return 
    Column(
      children: [
        AppGenericCard(
          padding: 16.w,
          color: Colors.white,
          borderRadius: 16.r,
          border: Border.all(color: Colors.grey.shade200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              16.verticalSpace,
              _buildContent(),
              // 20.verticalSpace,
              // _buildActions(),
            ],
          ),
        ),

       const SizedBox(height: 30,),

       _buildActions(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20.r,
          backgroundColor: Colors.transparent,
          backgroundImage: const AssetImage("assets/images/daii.png"),
        ),
        12.horizontalSpace,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("رفيق الخبير التربوي", style: AppTextStyles.extrabold16cairo),
            Text(
              "منذ قليل • خطة تربوية مخصصة",
              style: AppTextStyles.regular16cairo.copyWith(color: Colors.grey, fontSize: 12.sp),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent() {
    return Directionality(
      textDirection: TextDirection.rtl, // لتنسيق النص العربي من اليمين لليسار صح
      child: Text(
        plan.planText,
        style: AppTextStyles.regular14cairo.copyWith(height: 1.6, color: Colors.black87),
      ),
    );
  }


  Widget _buildActions() {


                      return CustomButton(
                        borderRadius: 10,
                        text:  'Download Pdf',
                        onPressed: onSavePdfPressed,
                        backgroundColor:  AppColors.primaryNormalActive,
                        textColor: Colors.white,
                        height: 48.h,

                      );
  }

}