
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/assess_result.dart';

enum AssessmentResultStatus { initial, loading, loaded, error }

class AssessmentResultState {
  final AssessmentResultStatus status;
  final AssessmentResult? result;
  final String? errorMessage;

  const AssessmentResultState({
    this.status = AssessmentResultStatus.initial,
    this.result,
    this.errorMessage,
  });

  // هذه الدالة ضرورية لتحديث الـ State في الـ Cubit
  AssessmentResultState copyWith({
    AssessmentResultStatus? status,
    AssessmentResult? result,
    String? errorMessage,
  }) {
    return AssessmentResultState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}