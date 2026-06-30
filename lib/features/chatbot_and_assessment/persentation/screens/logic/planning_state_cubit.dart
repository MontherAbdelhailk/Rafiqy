import 'dart:io';
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/parenting_plan.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/parenting_planning_repo.dart';
import 'package:universal_html/html.dart' as html;

abstract class ParentingPlanState {}
class ParentingPlanInitial extends ParentingPlanState {}
class ParentingPlanLoading extends ParentingPlanState {}
class ParentingPlanSuccess extends ParentingPlanState {
  final List<ParentingPlanEntity> plans;
  ParentingPlanSuccess(this.plans);
}
class ParentingPlanError extends ParentingPlanState {
  final String message;
  ParentingPlanError(this.message);
}
class SavePdfLoading extends ParentingPlanState {}
class SavePdfSuccess extends ParentingPlanState {}

class ParentingPlanCubit extends Cubit<ParentingPlanState> {
  final ParentingPlanRepo _repo;
  ParentingPlanCubit(this._repo) : super(ParentingPlanInitial());

  Future<void> fetchPlan(String userId) async {
    emit(ParentingPlanLoading());
    try {
      final response = await _repo.getParentingPlan(userId);
      emit(ParentingPlanSuccess(response.plans));
    } catch (e) {
      emit(ParentingPlanError(e.toString()));
    }
  }

  Future<void> downloadPdf(String userId) async {
    try {
      // 🌟 تعديل 1: عملنا emit للـ State المخصصة للـ PDF اللي إنتِ كرباها فوق عشان الكروت متختفيش
      emit(SavePdfLoading()); 

      final bytes = await _repo.downloadPlanPdf(userId);
      final fileName = 'parenting_plan_$userId.pdf';

      // 🌟 تعديل 2: تحويل دقيق ومضمون للـ Bytes لـ Uint8List عشان الفايل ميبقاش Corrupted ويفتح علطول
      final Uint8List pdfBytes = Uint8List.fromList(bytes);

      if (kIsWeb) {
        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..style.display = 'none'; // حتة شياكة لإخفاء اللينك الوهمي
          
        html.document.body?.children.add(anchor); // بنضيف اللينك للصفحة عشان المتصفح يلقطه
        anchor.click(); 
        
        anchor.remove(); // بنحذفه فوراً بعد الداونلود
        html.Url.revokeObjectUrl(url);
        
        // 🌟 تعديل 3: بنرجع الـ النجاح الخاص بالـ PDF من غير ما نبعت لستة فاضية تفرغ الشاشة
        emit(SavePdfSuccess()); 
      } 
      else {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        
        // 🌟 تعديل 4: كتبنا الـ pdfBytes الصافية وعملنا flush للتأكيد التام على نزول الملف بالكامل
        await file.writeAsBytes(pdfBytes, flush: true);
        
        // تأخير بسيط بمقدار 300 مللي ثانية للتأكد إن نظام التشغيل سيف الفايل على الهارد ديسك
        await Future.delayed(const Duration(milliseconds: 300));
        
        await OpenFilex.open(filePath);
        
        // 🌟 تعديل 5: إطلاق حالة نجاح الـ PDF
        emit(SavePdfSuccess());
      }
      
    } catch (e) {
      // لو حصل مشكلة نطبع الأيرور ونبعته في الـ State
      emit(ParentingPlanError("فشل تحميل ملف الـ PDF: ${e.toString()}"));
    }
  }
}