import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_result_state.dart';

class AssessmentResultCubit extends Cubit<AssessmentResultState> {
  final AssessmentRepository _assessmentRepository;

  AssessmentResultCubit(this._assessmentRepository) 
      : super(AssessmentResultState(status: AssessmentResultStatus.initial));

  Future<void> loadResults({
    required String userId,
    required int childAge,
    required List<AssessmentQuestion> answeredQuestions,
  }) async {
    emit(state.copyWith(status: AssessmentResultStatus.loading));
    
    try {
      final resultData = await _assessmentRepository.submitAssessment(
        userId: userId,
        childAge: childAge,
        answeredQuestions: answeredQuestions,
      );

      print("🚀 Success inside loadResults! Main Trait: ${resultData.mainTrait}");
      print("📊 Scores count: ${resultData.scores.length}");

      emit(state.copyWith(
        status: AssessmentResultStatus.loaded, 
        result: resultData,
      ));
      
    } catch (e) {
      print("❌ Error inside loadResults: $e");
      emit(state.copyWith(status: AssessmentResultStatus.error, errorMessage: e.toString()));
    }
  }
}