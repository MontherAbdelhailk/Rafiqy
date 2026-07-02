// features/chatbot_and_assessment/persentation/widgets/floating_consultation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/di/dependency_injection.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/booking/presentation/logic/slots_cubit.dart';
import 'package:rafiq/features/booking/presentation/screens/select_date_screen.dart';

class FloatingConsultationCard extends StatelessWidget {
  const FloatingConsultationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10), // تأثير الـ Float
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 40,right: 40,left: 40),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.all( Radius.circular(24.r)),
                  child: Image.asset(
                    'assets/images/consultation.avif',
                    height: 260.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 15.h,
                  right: 15.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: const Color(0xffB6C93B),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text('Top Rated', style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.w,left:20.w, right:20.w, bottom:10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1-on-1 Consultation', style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack)),
                SizedBox(height: 20.h),
                Text(
'Get personalized guidance from Rafiqy to\n'
'help you navigate your journey with expert\n' 
'advice tailored to your specific needs..',                      style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey7),
                ),
                SizedBox(height: 20.h),
                                Container(width: 300,height: 1,color: AppColors.grey5,),
                                                SizedBox(height: 15.h),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfo(Icons.access_time, '45 mins'),
                    _buildInfo(Icons.payments_outlined, '750 EGP'),
                  ],
                ),
                SizedBox(height: 15.h),

                                Container(width: 300,height: 1,color: AppColors.grey5,),

                            const    SizedBox(height: 18,),

                                                Center(
                                                  child: CustomButton(
                                                                    text: 'Book Now',
                                                                    height: 40.h,
                                                                    width: 130,
                                                                    borderRadius: 12.r,
                                                                    onPressed: () {
                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          settings: const RouteSettings(name: 'select_date'),
                                                                          builder: (_) => BlocProvider(
                                                                            create: (_) => getIt<SlotsCubit>(),
                                                                            child: const SelectDateScreen(),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                ),

                                

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: const Color(0xffB6C93B)),
        SizedBox(width: 5.w),
        Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
      ],
    );
  }
}