import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/use_cases/get_assessment.dart';
import 'package:rafiq/features/chatbot_and_assessment/persentation/screens/logic/assess_state.dart';
import 'package:rafiq/features/chatbot_and_assessment/domain/repos/assessment_repo.dart';

class AssessmentCubit extends Cubit<AssessmentState> {
  final GetAssessmentQuestions getAssessmentQuestions;
  final AssessmentRepository repository; 

  AssessmentCubit(this.getAssessmentQuestions, this.repository) : super(AssessmentState());

  Future<void> loadQuestions() async {
    emit(state.copyWith(status: AssessmentStatus.loading));
    try {
      final questions = await getAssessmentQuestions();
      emit(state.copyWith(status: AssessmentStatus.loaded, questions: questions));
    } catch (e) {
      emit(state.copyWith(status: AssessmentStatus.error));
    }
  }

  void selectAnswer(String answer) {
    final currentQuestion = state.questions[state.currentQuestionIndex];
    
    final int score = currentQuestion.options.indexOf(answer) + 1;

    final updatedQuestions = List<AssessmentQuestion>.from(state.questions);
    updatedQuestions[state.currentQuestionIndex] = currentQuestion.copyWith(
      selectedAnswer: answer,
      selectedScore: score,
    );
    
    emit(state.copyWith(questions: updatedQuestions));
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      emit(state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1));
    }
  }

  Future<bool> sendFinalAssessment(String userId, int childAge) async {
    try {
      await repository.submitAssessment(
        userId: userId,
        childAge: childAge,
        answeredQuestions: state.questions,
      );
      return true;
    } catch (e) {
      print("Error during submission cubit: $e");
      return false;
    }
  }
}