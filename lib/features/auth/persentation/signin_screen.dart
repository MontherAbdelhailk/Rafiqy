import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/apptextformfield.dart';
import 'package:rafiq/core/widgets/custom_appbar.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/auth/persentation/logic/signin_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/signin_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController usernameController;
  late TextEditingController passwordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<bool> isPasswordObscure = ValueNotifier<bool>(true);
  String? loginError;

  @override
  void initState() {
    super.initState();
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    usernameController.addListener(_clearError);
    passwordController.addListener(_clearError);
  }

  void _clearError() {
    if (loginError != null) {
      setState(() {
        loginError = null;
      });
    }
  }

  @override
  void dispose() {
    usernameController.removeListener(_clearError);
    passwordController.removeListener(_clearError);
    usernameController.dispose();
    passwordController.dispose();
    isPasswordObscure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: const CustomAppBar(title: "Login"),
      resizeToAvoidBottomInset: true,
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
                  SizedBox(height: 30.h),

                  // ── Username field (SRS §1.2 — login with username) ─────
                  _buildLabel('Username'),
                  SizedBox(height: 10.h),
                  AppTextFormField(
                    hintText: 'e.g. ahmed_m',
                    controller: usernameController,
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                    suffixIcon: const Icon(Icons.alternate_email, color: AppColors.secondaryLightactive),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Please enter your username' : null,
                  ),
                  SizedBox(height: 14.h),

                  // ── Password ────────────────────────────────────────────
                  _buildLabel('Password'),
                  SizedBox(height: 10.h),
                  ValueListenableBuilder<bool>(
                    valueListenable: isPasswordObscure,
                    builder: (context, obscureValue, child) {
                      return AppTextFormField(
                        hintText: '••••••••',
                        isObscureText: obscureValue,
                        controller: passwordController,
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                        suffixIcon: GestureDetector(
                          onTap: () => isPasswordObscure.value = !isPasswordObscure.value,
                          child: Icon(
                            obscureValue ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.secondaryLightactive,
                          ),
                        ),
                        validator: (value) =>
                            (value == null || value.isEmpty) ? 'Password is required' : null,
                      );
                    },
                  ),
                  if (loginError != null) ...[
                    SizedBox(height: 8.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        loginError!,
                        style: AppTextStyles.regular14cairo.copyWith(color: Colors.red),
                      ),
                    ),
                  ],
                  SizedBox(height: 10.h),

                  // ── Forgot password ─────────────────────────────────────
                  _buildForgetPassword(context),
                  24.verticalSpace,

                  // ── Login Button ────────────────────────────────────────
                  BlocConsumer<LoginCubit, LoginState>(
                    listener: (context, state) {
                      if (state is LoginSuccess) {
                        context.go(AppRouter.homeView);
                      } else if (state is LoginError) {
                        setState(() {
                          loginError = state.message;
                        });
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        borderRadius: 10,
                        text: state is LoginLoading ? 'Logging in...' : 'Login',
                        onPressed: state is LoginLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  context.read<LoginCubit>().login(
                                        usernameController.text.trim(),
                                        passwordController.text,
                                      );
                                }
                              },
                        backgroundColor:
                            state is LoginLoading ? Colors.grey : AppColors.primaryNormalActive,
                        textColor: Colors.white,
                        height: 50.h,
                      );
                    },
                  ),

                  20.verticalSpace,
                  _buildSocialDivider(),
                  20.verticalSpace,
                  _buildSocialButtons(context),
                  16.verticalSpace,

                  // ── Don't have an account? ──────────────────────────────
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1),
                        ),
                        GestureDetector(
                          onTap: () => context.push(AppRouter.signUp),
                          child: Text(
                            "Sign Up",
                            style: AppTextStyles.bold16cairo
                                .copyWith(color: AppColors.primaryNormalActive),
                          ),
                        ),
                      ],
                    ),
                  ),
                  24.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFC2C2C2))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text(
            "Or login with",
            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1),
          ),
        ),
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFC2C2C2))),
      ],
    );
  }

  Widget _buildSocialButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          iconPath: 'assets/images/google.svg',
          label: 'Google',
          onTap: () {
            // TODO: wire to SocialLoginCubit.signInWithGoogle()
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Google Sign-In coming soon')),
            );
          },
        ),
        20.horizontalSpace,
        _socialButton(
          iconPath: null,
          label: 'Apple',
          icon: const Icon(Icons.apple, size: 28, color: Colors.black),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apple Sign-In coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _socialButton({
    String? iconPath,
    Widget? icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE0E0E0)),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconPath != null) SvgPicture.asset(iconPath, width: 22.w, height: 22.h),
            if (icon != null) icon,
            8.horizontalSpace,
            Text(label, style: AppTextStyles.bold14cairo.copyWith(color: AppColors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        label,
        style: AppTextStyles.bold16cairo.copyWith(color: Colors.black),
      ),
    );
  }

  Widget _buildForgetPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => context.push(AppRouter.forgetPassword),
        child: Text(
          "Forgot password?",
          style: AppTextStyles.regular14cairo.copyWith(
            color: Colors.black54,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}