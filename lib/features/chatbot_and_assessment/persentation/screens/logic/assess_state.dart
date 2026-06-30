// features/assessment/presentation/cubit/assessment_state.dart

import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assessment_q.dart';

enum AssessmentStatus { initial, loading, loaded, error }

class AssessmentState {
  final AssessmentStatus status;
  final int currentQuestionIndex;
  final List<AssessmentQuestion> questions;

  AssessmentState({
    this.status = AssessmentStatus.initial,
    this.currentQuestionIndex = 0,
    this.questions = const [],
  });

  AssessmentQuestion? get currentQuestion => 
      questions.isNotEmpty ? questions[currentQuestionIndex] : null;
  
  bool get isLastQuestion => currentQuestionIndex == questions.length - 1;
  double get progress => questions.isEmpty ? 0 : (currentQuestionIndex + 1) / questions.length;

  AssessmentState copyWith({
    AssessmentStatus? status,
    int? currentQuestionIndex,
    List<AssessmentQuestion>? questions,
  }) {
    return AssessmentState(
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questions: questions ?? this.questions,
    );
  }
}