// features/chatbot_and_assessment/persentation/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/book_session/persentation/screens/confirmation_screen.dart';
import 'package:rafiq/features/book_session/persentation/widgets/credit_card.dart';
import 'package:rafiq/features/book_session/persentation/widgets/digital_wallent.dart';
import 'package:rafiq/features/book_session/persentation/widgets/order_sammry.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title:  Text('Payment',style:  AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            const CreditCardSection(),
            SizedBox(height: 24.h),
            const DigitalWalletSection(), 
            SizedBox(height: 24.h),
            const OrderSummaryCard(), 
            SizedBox(height: 30.h),
            CustomButton(
              text: 'Pay Now',
              textstyle: AppTextStyles.regular16cairo.copyWith(color: Colors.white),
              height: 55.h,
              borderRadius: 15.r,
              onPressed: () {
     Navigator.push(context, MaterialPageRoute(builder: (_) => ConfirmationScreen()));
              },
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}