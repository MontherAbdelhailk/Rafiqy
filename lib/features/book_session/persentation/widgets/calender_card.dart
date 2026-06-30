// features/chatbot_and_assessment/persentation/widgets/calendar_floating_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarFloatingCard extends StatelessWidget {
  final DateTime selectedDay;
  final Function(DateTime) onDaySelected;

  const CalendarFloatingCard({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10), // تأثير الـ Float
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2023, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: selectedDay,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: (selected, focused) => onDaySelected(selected),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[400]),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[400]),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12.sp, color: Colors.blueGrey[200]),
          weekendStyle: TextStyle(fontSize: 12.sp, color: Colors.blueGrey[200]),
        ),
        calendarStyle: CalendarStyle(
          selectedDecoration: BoxDecoration(
            color: const Color(0xffB6C93B),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffB6C93B).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          todayDecoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10.r),
          ),
          defaultTextStyle: TextStyle(fontSize: 14.sp),
        ),
      ),
    );
  }
}