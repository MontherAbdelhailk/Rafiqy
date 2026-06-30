// features/chatbot_and_assessment/persentation/screens/select_time_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/book_session/persentation/screens/payment_screen.dart';
import 'package:rafiq/features/book_session/persentation/widgets/slot_time.dart';

class SelectTimeScreen extends StatefulWidget {
  const SelectTimeScreen({super.key});

  @override
  State<SelectTimeScreen> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends State<SelectTimeScreen> {
  String selectedTime = "09:30 AM"; // الوقت المختار افتراضياً زي الصورة

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title:  Text('Select Time',style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking for', style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey3)),
                  SizedBox(height: 8.h),
                  Text('Monday, Oct 24', style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack)),
                  
                  SizedBox(height: 30.h),
                  
                  // 1. Morning Slots
                  _buildSectionHeader(Icons.wb_sunny_outlined, 'Morning Slots'),
                  _buildTimeGrid(["09:00 AM", "09:30 AM", "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM"], 
                      bookedTimes: ["10:30 AM"]), // مثال لموعد محجوز

                  SizedBox(height: 30.h),

                  // 2. Afternoon Slots
                  _buildSectionHeader(Icons.wb_cloudy_outlined, 'Afternoon Slots'),
                  _buildTimeGrid(["01:00 PM", "01:30 PM", "02:00 PM", "02:30 PM", "03:00 PM", "03:30 PM"], 
                      bookedTimes: ["02:30 PM"]),

                  SizedBox(height: 30.h),

                  // 3. Evening Slots
                  _buildSectionHeader(Icons.nightlight_round_outlined, 'Evening Slots'),
                  _buildTimeGrid(["05:00 PM", "05:30 PM", "06:00 PM"], 
                      bookedTimes: ["05:30 PM"]),
                  
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
          
          // Button القسم السفلي
          Padding(
            padding: EdgeInsets.all(24.w),
            child: CustomButton(
              text: 'Confirm Booking',
              height: 55.h,
              borderRadius: 15.r,
              onPressed: () {
                                                                                        Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PaymentScreen()),
                              );

                
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: AppColors.lightYellow),
        SizedBox(width: 8.w),
        Text(title, style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack)),
      ],
    );
  }

  Widget _buildTimeGrid(List<String> times, {List<String> bookedTimes = const []}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 2.3, // عشان تطلع مستطيلة زي الصورة
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        return TimeSlotItem(
          time: time,
          isSelected: selectedTime == time,
          isBooked: bookedTimes.contains(time),
          onTap: () => setState(() => selectedTime = time),
        );
      },
    );
  }
}