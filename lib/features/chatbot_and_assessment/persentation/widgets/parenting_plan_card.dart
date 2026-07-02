import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/parenting_plan.dart';
import 'package:readmore/readmore.dart';
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
    textDirection: TextDirection.rtl,
    child: ReadMoreText(
      plan.planText,
      trimLines: 9,
      trimMode: TrimMode.Line,
trimCollapsedText: ' Read more',
trimExpandedText: ' Show less',
      style: AppTextStyles.regular14cairo.copyWith(
        height: 1.6,
        color: Colors.black87,
      ),
      moreStyle: AppTextStyles.regular14cairo.copyWith(
        color: AppColors.primaryNormalActive,
      ),
      lessStyle: AppTextStyles.regular14cairo.copyWith(
        color: AppColors.primaryNormalActive,
      ),
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