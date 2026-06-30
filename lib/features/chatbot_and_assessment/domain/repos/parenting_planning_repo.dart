import 'package:dio/dio.dart';
import 'package:rafiq/core/networking/api_consumer.dart'; 
import 'package:rafiq/features/chatbot_and_assessment/data/models/parenting_plan_model.dart';

class ParentingPlanRepo {
  final ApiConsumer _apiConsumer;

  ParentingPlanRepo(this._apiConsumer);

  Future<ParentingPlanResponse> getParentingPlan(String userId) async {
    try {
      final response = await _apiConsumer.get('parenting-plans/$userId');
      
      return ParentingPlanResponse.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }


Future<List<int>> downloadPlanPdf(String userId) async { // 👈 غيرتها لـ String لو الـ userId عندك String
  try {
    final response = await _apiConsumer.get(
      'export-plan-pdf/$userId',
      options: Options(responseType: ResponseType.bytes), 
    );
    
    return List<int>.from(response); 
  } catch (e) {
    rethrow;
  }
}
}