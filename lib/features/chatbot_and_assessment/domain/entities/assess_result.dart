// features/assessment/domain/entities/assessment_result.dart

class AssessmentResult {
  final String mainTrait;
  final String description;
  final List<TraitScore> scores;
  final List<String>? guidelines;
  final int confidenceScore; 
  final Map<String, double> dimensionScores; 

  AssessmentResult({
    required this.mainTrait,
    required this.description,
    required this.scores,
    this.guidelines,
    required this.confidenceScore, 
    required this.dimensionScores,
  });

  factory AssessmentResult.fromJson(Map<String, dynamic> json) {
    // 1. الدخول إلى كائن الـ profile والـ meta
    final profile = json['profile'] ?? {};
    final meta = json['assessment_meta'] ?? {};
    final listPersonalities = profile['possible_personalities'] as List? ?? [];

    // 2. تحديد الشخصية الرئيسية (أول عنصر في الـ list هو الأعلى تطابقاً دائمًا)
    String mainTraitName = "المفكر";
    String mainDescription = "بحاجة إلى تحديات ذهنية وبيئة هادئة.";
    
    if (listPersonalities.isNotEmpty) {
      final topPersonality = listPersonalities.first;
      mainTraitName = topPersonality['name'] ?? topPersonality['id'] ?? "المفكر";
      mainDescription = "يحتاج إلى: ${topPersonality['need'] ?? 'وقت هادئ + تحديات ذهنية'}";
    }

    final traitScoresMap = profile['trait_scores'] as Map<String, dynamic>? ?? {};
    List<TraitScore> parsedScores = [];
    
    traitScoresMap.forEach((key, value) {
      parsedScores.add(
        TraitScore(
          name: key, // سيأخذ: focus, leadership, sociability... إلخ
          score: (value as num).toInt(),
          description: _generateTraitDescription(key, (value as num).toInt()), // توليد وصف ديناميكي باللغة العربية
        ),
      );
    });

    Map<String, double> parsedDimensions = {};
    for (var p in listPersonalities) {
      final String id = p['id'] ?? 'unknown';
      final double match = (p['match'] as num? ?? 0).toDouble();
      parsedDimensions[id] = match; // يملأ الـ Map بـ (thinker: 60, independent: 57...)
    }

    if (parsedDimensions.isEmpty) {
      parsedDimensions = {"thinker": 60, "independent": 57, "planner": 55, "challenger": 52};
    }

    return AssessmentResult(
      mainTrait: mainTraitName,
      description: mainDescription,
      scores: parsedScores,
      confidenceScore: json['assessment_confidence'] ?? meta['confidence'] ?? 0,
      dimensionScores: parsedDimensions,
      guidelines: json['note'] != null ? [json['note']] : [profile['note'] ?? "النتيجة إرشادية وليست تشخيصًا."],
    );
  }

  static String _generateTraitDescription(String traitName, int score) {
    switch (traitName.toLowerCase()) {
      case 'focus':
        return score > 50 ? 'يمتلك الطفل قدرة ممتازة على التركيز وإنهاء المهام.' : 'قد يحتاج الطفل لتمارين لزيادة الانتباه.';
      case 'leadership':
        return score > 50 ? 'يظهر مهارات قيادية عالية وقدرة على المبادرة.' : 'يحتاج إلى تعزيز الثقة بالنفس والمبادرة الجماعية.';
      case 'sociability':
        return score > 50 ? 'طفل اجتماعي للغاية ومحب لتكوين الصداقات.' : 'يميل الطفل إلى الهدوء والاستقلالية الاجتماعية.';
      default:
        return 'سمة شخصية تم قياسها بناءً على اختبار رفيق الإرشادي.';
    }
  }
}

class TraitScore {
  final String name;
  final int score;
  final String description;

  TraitScore({
    required this.name, 
    required this.score, 
    required this.description,
  });
}