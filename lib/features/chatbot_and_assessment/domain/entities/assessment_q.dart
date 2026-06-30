class AssessmentQuestion {
  final String id; 
  final String questionText;
  final List<String> options;
  final String? selectedAnswer;
  final int? selectedScore; 

  AssessmentQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    this.selectedAnswer,
    this.selectedScore,
  });

  AssessmentQuestion copyWith({String? selectedAnswer, int? selectedScore}) {
    return AssessmentQuestion(
      id: id,
      questionText: questionText,
      options: options,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      selectedScore: selectedScore ?? this.selectedScore,
    );
  }
}