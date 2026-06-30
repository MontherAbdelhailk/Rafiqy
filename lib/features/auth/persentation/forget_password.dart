import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/apptextformfield.dart';
import 'package:rafiq/core/widgets/custom_appbar.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_state.dart';

class ForgetPasswordView extends StatefulWidget {
  const ForgetPasswordView({super.key});

  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  late TextEditingController phoneController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // بنكريت الـ Cubit هنا عن طريق GetIt
      create: (context) => getIt<ForgetPasswordCubit>(),
      child: Scaffold(
              appBar:  CustomAppBar(title: "Forget Password"),

        backgroundColor: AppColors.babypink,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    43.verticalSpace,
                    _buildLabel('Phone Number'),
                    _buildPhoneField(),
                    43.verticalSpace,
                    
                    BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
                      listener: (context, state) {
                        if (state is ForgetPasswordSuccess) {
context.push(AppRouter.otpView, extra: phoneController.text);                        } else if (state is ForgetPasswordError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                          );
                        }
                      },
                      builder: (context, state) {
                        return CustomButton(
                          borderRadius: 10,
                          text: state is ForgetPasswordLoading ? 'Sending...' : 'Send',
                          onPressed: state is ForgetPasswordLoading 
                              ? null 
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    context.read<ForgetPasswordCubit>().sendOtp(phoneController.text);
                                  }
                                },
                          backgroundColor: AppColors.primaryNormalActive,
                          textColor: Colors.white,
                          height: 48.h,
                        );
                      },
                    ),
                    30.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets عشان الكود يبقى Senior ومنظم ---


  Widget _buildHeader() {
    return Column(
      children: [
        18.verticalSpace,
        Center(
          child: Text(
"Please enter your Phone Number. You\nwill receive an OTP code to create a new password\nvia Phone",            textAlign: TextAlign.center,
            style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey1), // قللت الحجم شوية عشان الـ UI
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return AppTextFormField(
      hintText: '01090895795',
      controller: phoneController,
      prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.primaryNormalActive),
      suffixIcon: const Icon(Icons.phone_outlined, color: AppColors.primaryNormalActive),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter your phone number';
        if (value.length != 11) return 'Please enter a valid phone number';
        return null;
      },
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h, top: 12.h),
      child: Text(
        label,
        style: AppTextStyles.bold16cairo.copyWith(color: Colors.black),
      ),
    );
  }
}