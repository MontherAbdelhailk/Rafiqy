// features/assessment/presentation/widgets/assessment_charts_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AssessmentChartsSection extends StatelessWidget {
  final int confidence;
  final Map<String, double> dimensions;

  const AssessmentChartsSection({
    super.key, 
    required this.confidence, 
    required this.dimensions
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, 
        children: [
          Expanded(
            child: _buildInfoCard(
              title: 'CONFIDENCE LEVEL',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 80.h,
                    width: 80.h,
                    child: CircularProgressIndicator(
                      value: confidence / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[200],
                      color: const Color(0xffB6C93B),
                    ),
                  ),
                  Text('$confidence%', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // 2. Trait Breakdown Card
          Expanded(
            child: _buildInfoCard(
              title: 'TRAIT BREAKDOWN',
              child: Column(
                children: [
                  Icon(Icons.hexagon_outlined, size: 60.h, color: Colors.blue[100]),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 4.h,
                    children: dimensions.entries.map((e) => _buildSmallScore(_translateDimensionId(e.key), e.value.toInt())).toList(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          SizedBox(height: 15.h),
          Expanded(child: Center(child: child)),
        ],
      ),
    );
  }

  Widget _buildSmallScore(String label, int score) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 3, backgroundColor: score > 50 ? Colors.green : Colors.orange),
        SizedBox(width: 4.w),
        Text('$label: $score', style: TextStyle(fontSize: 10.sp)),
      ],
    );
  }

  String _translateDimensionId(String id) {
    switch (id.toLowerCase()) {
      case 'thinker': return 'المفكر';
      case 'independent': return 'المستقل';
      case 'planner': return 'المنظم';
      case 'challenger': return 'المجادل';
      case 'energetic': return 'النشيط';
      default: return id;
    }
  }
}