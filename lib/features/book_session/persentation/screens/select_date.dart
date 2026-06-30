// features/chatbot_and_assessment/persentation/screens/select_date_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/book_session/persentation/screens/payment_screen.dart';
import 'package:rafiq/features/book_session/persentation/screens/select_time.dart';
import 'package:rafiq/features/book_session/persentation/widgets/calender_card.dart';

class SelectDateScreen extends StatefulWidget {
  const SelectDateScreen({super.key});

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        foregroundColor: AppColors.babypink,
        title:  Text('Select Date',style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDark)),
        centerTitle: true,
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back,color: AppColors.darkblack,)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: 
      Padding(
        padding: const EdgeInsets.only(left: 30,right: 30),
        child: Column(
          children: [
            // 1. Progress Bar
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: LinearProgressIndicator(
                      
                      borderRadius: BorderRadius.circular(10),
                      minHeight: 7,
                      value: 0.35, color: AppColors.lightYellow, backgroundColor:AppColors.ligthgrey),
                  ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(left:  24.w,right:24.w ,bottom: 24.w, top: 19.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                                        SizedBox(height: 20.h),

                    Text('When would you like to book?', style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack)),
                    SizedBox(height: 10.h),
                    Text('Select a date for your upcoming session.', style: AppTextStyles.regular14cairo.copyWith(color:AppColors.grey3 )),
                    
                    SizedBox(height: 30.h),
                    
                    CalendarFloatingCard(
                      selectedDay: _selectedDay,
                      onDaySelected: (day) => setState(() => _selectedDay = day),
                    ),
                    
                    SizedBox(height: 20.h),
                    
                    // 3. Legend (الرموز التوضيحية)
                    _buildLegend(),
                  ],
                ),
              ),
            ),
            
            // 4. Bottom Summary & Button
            _buildBottomSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(AppColors.primaryNormal, 'Selected'),
        SizedBox(width: 20.w),
        _legendItem(AppColors.ligthgrey!, 'Available'),
        SizedBox(width: 20.w),
        _legendItem(AppColors.ligthgrey!, 'Booked'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(radius: 4.r, backgroundColor: color),
        SizedBox(width: 6.w),
        Text(label, style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey3)),
      ],
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
     //   borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Date', style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey3)),
                  Text('Oct 12, 2023', style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Session Fee', style: TextStyle(color: Colors.grey[400], fontSize: 12.sp)),
                  Text('\$45.00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
                ],
              ),
            ],
          ),
          SizedBox(height: 20.h),
          CustomButton(
            text: 'Next',
            height: 55.h,
            borderRadius: 15.r,
            width: 100.w,
            onPressed: () {
                                                                        Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SelectTimeScreen()),
                              );

              
            },
          ),
        ],
      ),
    );
  }
}