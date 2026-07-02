import 'package:dio/dio.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assess_result.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo.dart';

class AssessmentRepositoryImpl implements AssessmentRepository {
  final Dio dio; 

  AssessmentRepositoryImpl(this.dio);

  @override
Future<List<AssessmentQuestion>> getQuestions(int childAge) async {
  
      try {
final response = await dio.get(
  'https://ribatbackend-production.up.railway.app/assessment/questions',
  queryParameters: {
    "age": childAge,
  },
);      
      if (response.statusCode == 200) {
        final data = response.data;
        
        final Map<String, dynamic> labels = data['scale']['labels'];
        final List<String> optionsList = labels.values.map((e) => e.toString()).toList();

        final List<dynamic> questionsJson = data['questions'];
        return questionsJson.map((q) => AssessmentQuestion(
          id: q['id'].toString(),
          questionText: q['text'],
          options: optionsList, 
          
        )).toList();
      } else {
        throw Exception("Failed to load questions");
      }
    } catch (e) {
      throw Exception("Error fetching questions: $e");
    }
  }

@override
  Future<AssessmentResult> submitAssessment({ 
    
    required String userId,
    required int childAge,
    required List<AssessmentQuestion> answeredQuestions,
  }) async {
    try {
      final List<Map<String, dynamic>> answersPayload = answeredQuestions.map((q) {
        return {
          "question_id": q.id,
          "score": q.selectedScore ?? 3 
        };
      }).toList();

      final Map<String, dynamic> body = {
        "user_id": userId,
        "child_age": childAge,
        "answers": answersPayload,
        "behavior_signals": {}
      };

      final response = await dio.post(
        'https://ribatbackend-production.up.railway.app/assessment/submit',
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        return AssessmentResult.fromJson(responseData);
      } else {
        throw Exception("Failed to parse result");
      }

    } catch (e) {
      print("--- [SUBMIT ASSESSMENT] Error: $e ---");
      throw Exception("Failed to submit assessment");
    }
  }
  }