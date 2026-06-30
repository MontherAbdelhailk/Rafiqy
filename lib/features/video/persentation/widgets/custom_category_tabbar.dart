import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class StaticCategoryTabBar extends StatefulWidget {
  const StaticCategoryTabBar({super.key});

  @override
  State<StaticCategoryTabBar> createState() => _StaticCategoryTabBarState();
}

class _StaticCategoryTabBarState extends State<StaticCategoryTabBar> {
  int _selectedIndex = 0;
  final List<String> _categories = const ['All', 'Guides', 'Tips'];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 45.h,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFF1F4E8),
            width: 1.h,
          ),
        ),
      ),
      child: 
      Padding(
        padding: const EdgeInsets.only(right: 150),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_categories.length, (index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  Text(
                    _categories[index],
                    style: AppTextStyles.bold16cairo.copyWith(
                      fontSize: 15.sp,
                      color: isSelected 
                          ? const Color(0xFF2D3142)
                          : const Color(0xFF8A92A6),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: isSelected ? 24.w : 0,
                    height: 3.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9DB454),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}