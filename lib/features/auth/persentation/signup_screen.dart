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
import 'package:rafiq/features/auth/domain/entities/sign_up_entity.dart';
import 'package:rafiq/features/auth/persentation/logic/signup_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/signup_state.dart';
import 'package:rafiq/features/auth/persentation/logic/social_login_cubit.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  late TextEditingController fullNameController;
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final ValueNotifier<bool> isPasswordObscure = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isConfirmPasswordObscure = ValueNotifier<bool>(true);

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    usernameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    isPasswordObscure.dispose();
    isConfirmPasswordObscure.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SocialLoginCubit, SocialLoginState>(
  listener: (context, state) {
    if (state is SocialLoginSuccess) {
      context.go(AppRouter.homeView);
    } else if (state is SocialLoginError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.message)),
      );
    }
  },
  child: 
    
    
    
    
    
     Scaffold(
      appBar:const CustomAppBar(title: "Sign Up"),
      backgroundColor: AppColors.babypink,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),

                  // Full Name
                  _buildLabel('Full Name'),
                  SizedBox(height: 10.h),
                  AppTextFormField(
                    hintText: 'e.g. Ahmed Mohamed',
                    controller: fullNameController,
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                    suffixIcon: const Icon(Icons.person_outline, color: AppColors.secondaryLightactive),
                    validator: (value) =>
                        (value == null || value.trim().length < 2) ? 'Please enter your full name' : null,
                  ),

                  SizedBox(height: 14.h),

                  // Username (unique)
                  _buildLabel('Username'),
                  SizedBox(height: 10.h),
                  AppTextFormField(
                    hintText: 'e.g. ahmed_m (unique)',
                    controller: usernameController,
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                    suffixIcon: const Icon(Icons.alternate_email, color: AppColors.secondaryLightactive),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Username is required';
                      if (value.trim().length < 3) return 'At least 3 characters';
                      final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
                      if (!usernameRegex.hasMatch(value.trim())) return 'Only letters, numbers and _';
                      return null;
                    },
                  ),

                  SizedBox(height: 14.h),

                  // Email
                  _buildLabel('Email'),
                  SizedBox(height: 10.h),
                  AppTextFormField(
                    hintText: 'ahmed@example.com',
                    controller: emailController,
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                    suffixIcon: const Icon(Icons.email_outlined, color: AppColors.secondaryLightactive),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        (value == null || value.isEmpty || !value.contains('@')) ? 'Invalid email address' : null,
                  ),

                  SizedBox(height: 14.h),

                  // Phone Number
                  _buildLabel('Phone Number'),
                  SizedBox(height: 10.h),
                  AppTextFormField(
                    hintText: '+201090895795',
                    controller: phoneController,
                    prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                    suffixIcon: const Icon(Icons.phone_outlined, color: AppColors.secondaryLightactive),
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        (value == null || value.trim().length < 7) ? 'Enter a valid phone number' : null,
                  ),

                  SizedBox(height: 14.h),

                  // Password
                  _buildLabel('Password'),
                  SizedBox(height: 10.h),
                  ValueListenableBuilder(
                    valueListenable: isPasswordObscure,
                    builder: (context, obscure, _) {
                      return AppTextFormField(
                        hintText: '••••••••',
                        isObscureText: obscure,
                        controller: passwordController,
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                        suffixIcon: IconButton(
                          onPressed: () => isPasswordObscure.value = !isPasswordObscure.value,
                          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          color: AppColors.secondaryLightactive,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 8) return 'Minimum 8 characters required';
                          final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
                          if (!passwordRegex.hasMatch(value)) {
                            return 'Must include uppercase, lowercase, number, and special character';
                          }
                          return null;
                        },
                      );
                    },
                  ),

                  SizedBox(height: 14.h),

                  // Confirm Password
                  _buildLabel('Confirm Password'),
                  SizedBox(height: 10.h),
                  ValueListenableBuilder(
                    valueListenable: isConfirmPasswordObscure,
                    builder: (context, obscure, _) {
                      return AppTextFormField(
                        hintText: '••••••••',
                        isObscureText: obscure,
                        controller: confirmPasswordController,
                        prefixIcon: const Icon(Icons.check_circle_outline, color: AppColors.grey1),
                        suffixIcon: IconButton(
                          onPressed: () => isConfirmPasswordObscure.value = !isConfirmPasswordObscure.value,
                          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          color: AppColors.secondaryLightactive,
                        ),
                        validator: (value) =>
                            (value != passwordController.text) ? 'Passwords do not match' : null,
                      );
                    },
                  ),

                  30.verticalSpace,

                  // Sign Up Button
                  BlocConsumer<SignupCubit, SignupState>(
                    listener: (context, state) {
                      if (state is SignupSuccess) {
                        context.go(AppRouter.homeView);
                      } else if (state is SignupError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        borderRadius: 10,
                        text: state is SignupLoading ? 'Creating Account...' : 'Sign Up',
                        onPressed: state is SignupLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  context.read<SignupCubit>().signup(
                                        SignupRequestEntity(
                                          fullName: fullNameController.text.trim(),
                                          username: usernameController.text.trim(),
                                          email: emailController.text.trim(),
                                          phone: phoneController.text.trim(),
                                          password: passwordController.text,
                                        ),
                                      );
                                }
                              },
                        backgroundColor:
                            state is SignupLoading ? Colors.grey : AppColors.primaryNormal,
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

                  // Already have an account?
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account? ",
                            style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1)),
                        GestureDetector(
                          onTap: () => context.push(AppRouter.signIn),
                          child: Text("Login",
                              style: AppTextStyles.bold16cairo
                                  .copyWith(color: AppColors.primaryNormal)),
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
     ),
    );
  }

  Widget _buildSocialDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(thickness: 1, color: Color(0xFFC2C2C2))),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          child: Text("Or sign up with",
              style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey1)),
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
          width: 340.w,
          iconPath: 'assets/images/google.svg',
          label: 'Google',
          onTap: () {
  context.read<SocialLoginCubit>().signInWithGoogle();
          },
        ),
     //   20.horizontalSpace,
        // _socialButton(
        //   iconPath: null,
        //   label: 'Apple',
        //   icon: const Icon(Icons.apple, size: 28, color: Colors.black),
        //   onTap: () {
        //     // TODO: wire to SocialLoginCubit.signInWithApple()
        //     ScaffoldMessenger.of(context).showSnackBar(
        //       const SnackBar(content: Text('Apple Sign-In coming soon')),
        //     );
        //   },
        // ),
      ],
    );
  }

  Widget _socialButton({
    String? iconPath,
    Widget? icon,
    required String label,
    required VoidCallback onTap,
    double? width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
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
  mainAxisAlignment: MainAxisAlignment.center, 
  
  mainAxisSize: MainAxisSize.max, 
  
  children: [
    if (iconPath != null) SvgPicture.asset(iconPath, width: 22.w, height: 22.h),
    if (icon != null) icon,
    8.horizontalSpace,
    Text(
      label, 
      style: AppTextStyles.bold14cairo.copyWith(color: AppColors.black),
    ),
  ],
),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bold16cairo.copyWith(color: AppColors.black),
    );
  }
}