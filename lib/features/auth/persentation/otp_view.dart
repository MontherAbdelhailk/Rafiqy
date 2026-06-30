import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/routes/app_routes.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_appbar.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_cubit.dart';
import 'package:rafiq/features/auth/persentation/logic/forget_pass_state.dart';


class OtpView extends StatefulWidget {
  final String phoneNumber; // بنستلم الرقم من الشاشة اللي فاتت

  const OtpView({super.key, required this.phoneNumber});

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  // 1. عملنا قائمة من الـ Controllers لـ 4 خانات
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  
  // ميثود بتجمع الأرقام من الـ 4 خانات وتحولهم لـ String واحد
  String get otpCode => _controllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    // مهم جداً نقفل الـ Controllers عشان الرام
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<ForgetPasswordCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.babypink,
              appBar:  CustomAppBar(title: "Enter your OTP code"),

        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  _buildHeader(),
                  35.verticalSpace,
                  
                  // 2. عرض خانات الـ OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (index) => _buildOtpBox(
                        index: index,
                        first: index == 0,
                        last: index == 3,
                      ),
                    ),
                  ),

                  35.verticalSpace,

                  // 3. التعامل مع الـ Logic عن طريق BlocConsumer
                  BlocConsumer<ForgetPasswordCubit, ForgetPasswordState>(
                    listener: (context, state) {
                      if (state is OtpSuccess) {
                        
                        context.push(AppRouter.createNewPasswordView,extra: state.token);
                      } else if (state is OtpError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    builder: (context, state) {
                      return CustomButton(
                        borderRadius: 10,
                        text: state is OtpLoading ? 'Verifying...' : 'Confirm',
                        onPressed: state is OtpLoading
                            ? null
                            : () {
                                if (otpCode.length == 4) {
                                  context.read<ForgetPasswordCubit>().verifyOtp(
                                        phone: widget.phoneNumber,
                                        otp: otpCode,
                                      );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please enter the full code")),
                                  );
                                }
                              },
                        backgroundColor: AppColors.primaryNormalActive,
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
    );
  }

  // --- مكونات الـ UI المنفصلة ---


  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "We just sent you a message to ${widget.phoneNumber},\nplease enter the OTP code below to identify your account.",
          textAlign: TextAlign.center,
          style: AppTextStyles.regular16cairo.copyWith(
            color: AppColors.grey,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpBox({required int index, required bool first, required bool last}) {
    return Container(
      height: 70.h,
      width: 64.w,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryNormal, width: 1),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.white, // خليتها أبيض عشان الأرقام تبان
      ),
      child: TextField(
        controller: _controllers[index],
        autofocus: first, // أول مربع يفتح الكيبورد لوحده
        onChanged: (value) {
          if (value.length == 1 && !last) {
            FocusScope.of(context).nextFocus(); // انقل للي بعده
          }
          if (value.isEmpty && !first) {
            FocusScope.of(context).previousFocus(); // ارجع للي قبله لو مسحت
          }
        },
        showCursor: false,
        textAlign: TextAlign.center,
        style: AppTextStyles.bold16cairo.copyWith(fontSize: 24.sp),
        keyboardType: TextInputType.number,
        inputFormatters: [
          LengthLimitingTextInputFormatter(1),
          FilteringTextInputFormatter.digitsOnly,
        ],
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "-",
          hintStyle: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}