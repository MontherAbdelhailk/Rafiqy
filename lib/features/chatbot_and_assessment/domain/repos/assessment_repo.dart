
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assess_result.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';

abstract class AssessmentRepository {

  Future<List<AssessmentQuestion>> getQuestions();
  Future<AssessmentResult> submitAssessment({
    required String userId,
    required int childAge,

    required List<AssessmentQuestion> answeredQuestions,

  });

}  