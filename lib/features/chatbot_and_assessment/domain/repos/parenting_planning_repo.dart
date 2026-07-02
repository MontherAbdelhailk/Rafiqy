import 'package:dio/dio.dart';
import 'package:rafiq/core/networking/api_consumer.dart'; 
import 'package:rafiq/features/chatbot_and_assessment/data/models/parenting_plan_model.dart';

class ParentingPlanRepo {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://ribatbackend-production.up.railway.app/",
      headers: {
        "Content-Type": "application/json",
      },
    ),
  );





  Future<ParentingPlanResponse> generateParentingPlan(String userId) async {
    try {
      final response = await dio.post(
        "generate-parenting-plan/$userId",
      );
      
      return ParentingPlanResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<ParentingPlanResponse> getParentingPlan(String userId) async {
    try {
      final response = await dio.get(
        "parenting-plans/$userId",
      );
      
      return ParentingPlanResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }


Future<List<int>> downloadPlanPdf(String userId) async { 
  try {
      final response = await dio.get(
        "export-plan-pdf/$userId",
        options: Options(responseType: ResponseType.bytes),
      );
    
    return List<int>.from(response.data); 
  } catch (e) {
    rethrow;
  }
}


}