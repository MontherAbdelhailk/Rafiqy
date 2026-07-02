import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/apptextformfield.dart';
import 'package:rafiq/core/widgets/custom_appbar.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_state.dart';

class CreateNewPasswordView extends StatefulWidget {
  final String token;

  const CreateNewPasswordView({super.key,  required this.token});

  @override
  State<CreateNewPasswordView> createState() => _CreateNewPasswordViewState();
}

class _CreateNewPasswordViewState extends State<CreateNewPasswordView> {
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  bool isPasswordObscure = true;
  bool isConfirmPasswordObscure = true;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ForgetPasswordCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.babypink,
        resizeToAvoidBottomInset: true,
                      appBar:  CustomAppBar(title: "Create New Password"),

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
                    35.verticalSpace,
                    
                    _buildLabel('New Password'),
                    _buildPasswordField(),
                    
                    35.verticalSpace,
                    
                    _buildLabel('Confirm New Password'),
                    _buildConfirmPasswordField(),
                    
                    35.verticalSpace,

                    BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
                      listener: (context, state) {
                        if (state is ResetPasswordSuccess) {
                          context.push(AppRouter.successConfirmationView);
                        } else if (state is ResetPasswordError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                          );
                        }
                      },
                      builder: (context, state) {
                        return CustomButton(
                           borderRadius: 10,

                          text: state is ResetPasswordLoading ? 'Saving...' : 'Confirm',
                          onPressed: state is ResetPasswordLoading 
                            ? null 
                            : () => _onConfirmPressed(context),
                          backgroundColor: AppColors.primaryNormal,
                          textColor: Colors.white,
                          height: 48.h,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  void _onConfirmPressed(BuildContext context) {
    if (formKey.currentState!.validate()) {
      context.read<ForgetPasswordCubit>().resetPassword(
            token: widget.token,
            
              password: passwordController.text,
          );
    }
  }

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h),
      child: IconButton(
        onPressed: () => context.pop(),
        icon: Icon(Icons.arrow_back, color: Colors.black, size: 28.sp),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        20.verticalSpace,
        Center(
          child: Text(
            "Create your own new password to reset your account.",
            textAlign: TextAlign.center,
            style: AppTextStyles.regular16merr.copyWith(color: AppColors.grey1, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return AppTextFormField(
      hintText: '*********',
      hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.secondaryNormal),
      isObscureText: isPasswordObscure,
      controller: passwordController,
      prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.primaryNormal),
      suffixIcon: IconButton(
        onPressed: () => setState(() => isPasswordObscure = !isPasswordObscure),
        icon: Icon(isPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        color: AppColors.primaryNormal,
      ),
      validator: (value) => (value == null || value.length < 8) ? 'Must be at least 8 chars' : null,
    );
  }

  Widget _buildConfirmPasswordField() {
    return AppTextFormField(
      hintText: '*********',
      hintStyle: AppTextStyles.regular14cairo.copyWith(color: AppColors.secondaryNormal),
      isObscureText: isConfirmPasswordObscure,
      controller: confirmPasswordController,
      prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.primaryNormal),
      suffixIcon: IconButton(
        onPressed: () => setState(() => isConfirmPasswordObscure = !isConfirmPasswordObscure),
        icon: Icon(isConfirmPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        color: AppColors.primaryNormal,
      ),
      validator: (value) {
        if (value != passwordController.text) return 'Passwords do not match';
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