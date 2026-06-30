// features/chatbot_and_assessment/persentation/screens/book_session_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart'; // تأكدي من مسار الـ CustomButton
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/features/booking/presentation/logic/slots_cubit.dart';
import 'package:rafiq/features/booking/presentation/screens/select_date_screen.dart';
import 'package:rafiq/features/book_session/persentation/widgets/floating_style_button.dart';
import '../widgets/floating_consultation_card.dart';

class BookSessionScreen extends StatefulWidget {
  const BookSessionScreen({super.key});

  @override
  State<BookSessionScreen> createState() => _BookSessionScreenState();
}

class _BookSessionScreenState extends State<BookSessionScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        title: Text(
          'Book Session',
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            const FloatingConsultationCard(),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}