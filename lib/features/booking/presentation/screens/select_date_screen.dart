// lib/features/booking/presentation/screens/select_date_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart';
import 'package:rafiq/features/booking/domain/entities/slot_entity.dart';
import 'package:rafiq/features/booking/presentation/logic/slots_cubit.dart';
import 'package:rafiq/features/booking/presentation/logic/slots_state.dart';
import 'package:table_calendar/table_calendar.dart';
import 'select_time_screen.dart';

class SelectDateScreen extends StatefulWidget {
  const SelectDateScreen({super.key});

  @override
  State<SelectDateScreen> createState() => _SelectDateScreenState();
}

class _SelectDateScreenState extends State<SelectDateScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Set<DateTime> _availableDays = {};

  @override
  void initState() {
    super.initState();
    // Load slots for the next 200 days (to reach Dec 31st)
    context.read<SlotsCubit>().loadSlots(
          from: DateTime.now(),
          to: DateTime.now().add(const Duration(days: 200)),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.babypink,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkblack),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Date',
          style: AppTextStyles.bold24cairo.copyWith(color: AppColors.secondaryDarker),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SlotsCubit, SlotsState>(
        builder: (context, state) {
          if (state is SlotsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryNormal),
              ),
            );
          }

          if (state is SlotsError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60.sp, color: AppColors.errorNormal),
                    SizedBox(height: 16.h),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
                    ),
                    SizedBox(height: 24.h),
                    CustomButton(
                      text: 'Retry',
                      height: 48.h,
                      borderRadius: 12.r,
                      onPressed: () => context.read<SlotsCubit>().loadSlots(
                            from: DateTime.now(),
                            to: DateTime.now().add(const Duration(days: 60)),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is SlotsLoaded) {
            _availableDays = context.read<SlotsCubit>().getAvailableDates();

            return Column(
              children: [
                // ── Calendar ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 200)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      enabledDayPredicate: (day) {
                        final normalized = DateTime(day.year, day.month, day.day);
                        return _availableDays.contains(normalized);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        _focusedDay = focusedDay;
                      },
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(
                          color: AppColors.primaryNormal,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryNormal),
                        ),
                        todayTextStyle: TextStyle(
                          color: AppColors.primaryNormalActive,
                          fontWeight: FontWeight.bold,
                        ),
                        disabledTextStyle: TextStyle(
                          color: AppColors.grey1.withValues(alpha: 0.4),
                        ),
                        markersMaxCount: 1,
                        outsideDaysVisible: false,
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: AppTextStyles.bold16cairo.copyWith(
                          color: AppColors.darkblack,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: AppColors.primaryNormal,
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: AppColors.primaryNormal,
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          final normalized = DateTime(day.year, day.month, day.day);
                          final hasSlots = _availableDays.contains(normalized);
                          if (hasSlots) {
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryNormal.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: AppColors.primaryDarkActive,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Legend ────────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Row(
                    children: [
                      Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryNormal.withValues(alpha: 0.5)),
                        ),
                      ),
                      8.horizontalSpace,
                      Text(
                        'Available dates',
                        style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                      ),
                      16.horizontalSpace,
                      Container(
                        width: 16.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.primaryNormal,
                          shape: BoxShape.circle,
                        ),
                      ),
                      8.horizontalSpace,
                      Text(
                        'Selected',
                        style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                // ── Selected date's available times preview ──────────────
                if (_selectedDay != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16.sp, color: AppColors.primaryNormal),
                        8.horizontalSpace,
                        Text(
                          DateFormat('EEEE, MMMM d').format(_selectedDay!),
                          style: AppTextStyles.bold16cairo.copyWith(color: AppColors.darkblack),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildSlotsPreview(context, _selectedDay!),
                ],

                const Spacer(),

                // ── Continue button ────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
                  child: CustomButton(
                    text: 'Continue to Select Time',
                    height: 55.h,
                    borderRadius: 15.r,
                    onPressed: _selectedDay == null
                        ? null
                        : () {
                            final slots = context.read<SlotsCubit>().getSlotsForDate(_selectedDay!);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BlocProvider.value(
                                  value: context.read<SlotsCubit>(),
                                  child: SelectTimeScreen(
                                    selectedDate: _selectedDay!,
                                    slots: slots,
                                  ),
                                ),
                              ),
                            );
                          },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSlotsPreview(BuildContext context, DateTime date) {
    final slots = context.read<SlotsCubit>().getSlotsForDate(date);
    if (slots.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Text(
          'No available slots for this date.',
          style: AppTextStyles.regular14cairo.copyWith(color: AppColors.grey8),
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Text(
        '${slots.length} slot${slots.length > 1 ? 's' : ''} available',
        style: AppTextStyles.regular14cairo.copyWith(color: AppColors.primaryNormalActive),
      ),
    );
  }
}
