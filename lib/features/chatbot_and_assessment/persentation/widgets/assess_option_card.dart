import 'package:flutter/material.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';

class OptionCard extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const OptionCard({super.key, required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryNormalActive : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color:AppColors.primaryLightActive),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: AppTextStyles.bold16inter.copyWith(color: isSelected ? Colors.white : Colors.black87) )),
            Icon(isSelected ? Icons.check_circle : Icons.radio_button_off, color: AppColors.primaryLightActive),
          ],
        ),
      ),
    );
  }
}