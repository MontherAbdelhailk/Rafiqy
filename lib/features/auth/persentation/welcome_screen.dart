import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  40.verticalSpace,
                  Text(
                    'Welcome to Rafiq',
                    style: AppTextStyles.bold28merr.copyWith(color: AppColors.secondaryNormal),
                  ),
                  
                  30.verticalSpace,
                  
                  SvgPicture.asset(
                    'assets/images/welcome_picture.svg',
                    height: 250.h, 
                    fit: BoxFit.contain,
                  ),
                  
                  30.verticalSpace,

                  Text(
                    "You’re not alone.\nAt Rafiq, we are always by your side, we truly listen to you, understand your feelings, and support you every step of the way.",
                    textAlign: TextAlign.center,
                    style: AppTextStyles.regular20merr.copyWith(color: AppColors.grey),
                  ),
                ],
              ),

              Column(
                children: [
                  Text(
                    "Lets get started",
                    style: AppTextStyles.regular16merr.copyWith(color: AppColors.secondaryNormal),
                  ),
                  
                  20.verticalSpace,

                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          height: 40,
                          text: 'Login',
                          onPressed: () => context.push(AppRouter.signIn),
                          backgroundColor: Colors.transparent,
                          textColor: AppColors.primaryNormalHover,
                          borderSide: const BorderSide(color: AppColors.primaryNormalHover),
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: CustomButton(
                          height: 40,
                          text: 'Sign Up',
                          onPressed: () => context.push(AppRouter.signUp),
                          backgroundColor: AppColors.primaryNormalActive,
                          textColor: Colors.white,
                          borderSide: const BorderSide(color: AppColors.primaryNormalActive),
                        ),
                      ),
                    ],
                  ),
                  40.verticalSpace, 
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}