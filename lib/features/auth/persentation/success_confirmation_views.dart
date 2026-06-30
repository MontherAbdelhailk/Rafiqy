import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';

class SuccessConfirmationView extends StatelessWidget {
  const SuccessConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              60.verticalSpace,

              Center(
                child: Text(
                  "Success confirmation",
                  style: AppTextStyles.extrabold28cairo.copyWith(
                    color: AppColors.primaryNormal,
                  ),
                ),
              ),

              const Spacer(),

Center(
                child: SvgPicture.asset(
                  'assets/images/Vector.svg',
                  width: 250.w,  
                  height: 250.h,
                ),
              ),
              const Spacer(),

              CustomButton(
                text: 'Return to Home',
                onPressed: () {
                    context.push(AppRouter.profileView);
                },
                backgroundColor: AppColors.primaryNormalActive,
                textColor: Colors.white,
                height: 48.h,
              ),

              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}