// features/assessment/presentation/pages/assessment_intro_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rafiq/core/thieming/app_colors.dart';
import 'package:rafiq/core/thieming/app_styles.dart';
import 'package:rafiq/core/widgets/custom_buttom.dart'; 
// تأكدي من عمل import الصحيح للمسار الجديد لصفحة الأسئلة
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/assessment_qs.dart'; 

class AssessmentIntroPage extends StatefulWidget {
  // 🚀 يفضل استلام الـ userId الحقيقي لليوزر الحالي هنا عشان نقضي على الـ Dummy data تماماً
  final String userId;

  const AssessmentIntroPage({
    super.key, 
    this.userId = "temp_user_123", // قيمة افتراضية لحين ربط الـ AuthCubit بتاعك بالكامل
  });

  @override
  State<AssessmentIntroPage> createState() => _AssessmentIntroPageState();
}

class _AssessmentIntroPageState extends State<AssessmentIntroPage> {
  String? _selectedChild;
  
  final List<String> _childrenage = ['1-3', '3-6', '6-9'];

  // 💡 دالة ذكية لتحويل الـ Text Range المختار من الـ Dropdown إلى رقم int حقيقي يفهمه السيرفر
  int _mapAgeRangeToInt(String? range) {
    switch (range) {
      case '1-3': return 3;
      case '3-6': return 5;
      case '6-9': return 8;
      default: return 5; // قيمة احتياطية آمنة
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        title: Text('Rafiq', style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                  child: Image.asset(
                    'assets/images/0to3.png', 
                    height: 240.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    children: [
                      Text(
                        'AI Child Assessment',
                        style: AppTextStyles.bold24cairo.copyWith(color: AppColors.darkblack)
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Select your child and answer a few questions to understand their personality.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.regular16cairo.copyWith(color: AppColors.grey8),
                      ),

                      SizedBox(height: 25.h),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start, 
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 10),
                            child: const Text("Child's Age"),
                          ),
                          SizedBox(height: 10.h),

                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            decoration: BoxDecoration(
                              color: AppColors.ligthgrey,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                dropdownColor: AppColors.ligthgrey,
                                value: _selectedChild,
                                hint: Text("Select Child", style: AppTextStyles.regular16cairo.copyWith(color: AppColors.darkblack)),
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey9),
                                items: _childrenage.map((String child) {
                                  return DropdownMenuItem<String>(
                                    value: child,
                                    child: Text(child, style: TextStyle(fontSize: 15.sp)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedChild = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 30.h),

                      CustomButton(
                        text: 'Start Assessment',
                        height: 50,
                        borderRadius: 12,
                        onPressed: _selectedChild == null 
                          ? null 
                          : () {
                              // 🚀 هنا تم حل المشكلة وتوصيل الـ Route بالبيانات الديناميكية كاملة
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AssessmentQuestionnairePage(
                                    userId: widget.userId, // تمرير الآيدي الحقيقي ديناميكياً
                                    childAge: _mapAgeRangeToInt(_selectedChild), // تمرير السن الحقيقي كـ int متوافق مع السيرفر
                                  ),
                                ),
                              );
                            },     
                        backgroundColor: AppColors.lightYellow,
                      ),
                      
                      SizedBox(height: 15.h),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                          SizedBox(width: 4.w),
                          Text(
                            'Takes about 5 minutes',
                            style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}