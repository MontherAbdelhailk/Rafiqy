
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo.dart';

class GetAssessmentQuestions {
  final AssessmentRepository repository;

  GetAssessmentQuestions(this.repository);

  Future<List<AssessmentQuestion>> call() async {
    return await repository.getQuestions();
  }
}