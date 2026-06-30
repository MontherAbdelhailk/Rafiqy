
import 'package:rafiq/features/chatbot_and_assessment/domain/entities/parenting_plan.dart';

class ParentingPlanResponse {
  final String userId;
  final int total;
  final List<ParentingPlanModel> plans;

  ParentingPlanResponse({required this.userId, required this.total, required this.plans});

  factory ParentingPlanResponse.fromJson(Map<String, dynamic> json) {
    return ParentingPlanResponse(
      userId: json['user_id'] ?? '',
      total: json['total'] ?? 0,
      plans: (json['plans'] as List? ?? [])
          .map((e) => ParentingPlanModel.fromJson(e))
          .toList(),
    );
  }
}

class ParentingPlanModel extends ParentingPlanEntity {
  ParentingPlanModel({
    required super.id,
    required super.planText,
    required super.createdAt,
  });

  factory ParentingPlanModel.fromJson(Map<String, dynamic> json) {
    return ParentingPlanModel(
      id: json['id'] ?? 0,
      planText: json['plan_text'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}