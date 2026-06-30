// lib/features/booking/presentation/screens/select_time_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/booking/domain/entities/slot_entity.dart';
import 'booking_review_screen.dart';

class SelectTimeScreen extends StatefulWidget {
  final DateTime selectedDate;
  final List<SlotEntity> slots;

  const SelectTimeScreen({
    super.key,
    required this.selectedDate,
    required this.slots,
  });

  @override
  State<SelectTimeScreen> createState() => _SelectTimeScreenState();
}

class _SelectTimeScreenState extends State<SelectTimeScreen> {
  SlotEntity? _selectedSlot;

  @override
  Widget build(BuildContext context) {
    // Filter active slots that are available, not booked, and start between 7:00 AM and 12:00 AM (Midnight)
    final activeSlots = widget.slots.where((s) {
      if (!s.canBook) return false;
      final hour = s.startTime.hour;
      return hour >= 7 && hour <= 23;
    }).toList();

    // Sort slots chronologically
    activeSlots.sort((a, b) => a.startTime.compareTo(b.startTime));

    // Group slots by time of day
    final morningSlots = activeSlots.where((s) => s.startTime.hour < 12).toList();
    final afternoonSlots = activeSlots.where((s) => s.startTime.hour >= 12 && s.startTime.hour < 17).toList();
    final eveningSlots = activeSlots.where((s) => s.startTime.hour >= 17).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'Select Time',
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
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
                  Text(
                    'Booking for',
                    style: AppTextStyles.bold14cairo.copyWith(color: AppColors.grey3),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(widget.selectedDate),
                    style: AppTextStyles.bold20cairo.copyWith(color: AppColors.darkblack),
                  ),
                  SizedBox(height: 30.h),

                  if (activeSlots.isEmpty) ...[
                    Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.h),
                        child: Text(
                          'No available slots for this date.',
                          style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Morning Slots
                    if (morningSlots.isNotEmpty) ...[
                      _buildSectionHeader(Icons.wb_sunny_outlined, 'Morning Slots'),
                      _buildTimeGrid(morningSlots),
                      SizedBox(height: 20.h),
                    ],

                    // Afternoon Slots
                    if (afternoonSlots.isNotEmpty) ...[
                      _buildSectionHeader(Icons.wb_cloudy_outlined, 'Afternoon Slots'),
                      _buildTimeGrid(afternoonSlots),
                      SizedBox(height: 20.h),
                    ],

                    // Evening Slots
                    if (eveningSlots.isNotEmpty) ...[
                      _buildSectionHeader(Icons.nightlight_round_outlined, 'Evening Slots'),
                      _buildTimeGrid(eveningSlots),
                      SizedBox(height: 20.h),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Bottom button
          Padding(
            padding: EdgeInsets.all(24.w),
            child: CustomButton(
              text: 'Continue to Review',
              height: 55.h,
              borderRadius: 15.r,
              onPressed: _selectedSlot == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingReviewScreen(
                            selectedSlot: _selectedSlot!,
                          ),
                        ),
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
        Icon(icon, size: 20.sp, color: AppColors.primaryNormal),
        SizedBox(width: 8.w),
        Text(
          title,
          style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
        ),
      ],
    );
  }

  Widget _buildTimeGrid(List<SlotEntity> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 2.3,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final timeString = DateFormat('hh:mm a').format(slot.startTime);
        final isSelected = _selectedSlot?.id == slot.id;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSlot = slot;
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryNormal
                  : Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryNormal
                    : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primaryNormal.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Text(
              timeString,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : const Color(0xff2D3748),
              ),
            ),
          ),
        );
      },
    );
  }
}
