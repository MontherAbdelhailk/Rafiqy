// features/chatbot_and_assessment/persentation/widgets/time_slot_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TimeSlotItem extends StatelessWidget {
  final String time;
  final bool isSelected;
  final bool isBooked; // لو الموعد محجوز أصلاً (اللون الباهت)
  final VoidCallback onTap;

  const TimeSlotItem({
    super.key,
    required this.time,
    required this.isSelected,
    required this.isBooked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isBooked ? null : onTap, // لو محجوز ميدوسش
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // اللون بيتغير بناءً على الحالة
          color: isSelected 
              ? const Color(0xffB6C93B) // الأخضر الليموني المختار
              : isBooked 
                  ? const Color(0xffF9F9F9) // خلفية باهتة للمحجوز
                  : Colors.white, // أبيض للمتاح
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: isSelected 
                ? const Color(0xffB6C93B) 
                : Colors.grey[200]!,
            width: 1.5,
          ),
          // الـ Shadow بيظهر بس في المختار عشان يـ Float
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xffB6C93B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          time,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isSelected 
                ? Colors.white 
                : isBooked 
                    ? Colors.grey[300] // نص باهت للمحجوز
                    : const Color(0xff2D3748), // لون داكن للمتاح
          ),
        ),
      ),
    );
  }
}