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
    final listPersonalities = json['possible_personalities'] as List? ?? [];

    String mainTraitName = "The Planner";
    String mainDescription = "Orderly, methodical, and motivated by structure, routine, and clear goals.";
    
    if (listPersonalities.isNotEmpty) {
      final topPersonality = listPersonalities.first;
      mainTraitName = topPersonality['name'] ?? "The Planner";
      mainDescription = topPersonality['description'] ?? "Orderly, methodical, and motivated by structure, routine, and clear goals.";
    }

    final traitScoresMap = json['trait_scores'] as Map<String, dynamic>? ?? {};
    List<TraitScore> parsedScores = [];
    
    traitScoresMap.forEach((key, value) {
      parsedScores.add(
        TraitScore(
          name: key,
          score: (value as num).toInt(),
          description: _generateTraitDescription(key, (value as num).toInt()),
        ),
      );
    });

    Map<String, double> parsedDimensions = {};
    for (var p in listPersonalities) {
      final String id = p['id'] ?? 'unknown';
      final double match = (p['match_pct'] as num? ?? p['match'] as num? ?? 0).toDouble();
      parsedDimensions[id] = match;
    }

    if (parsedDimensions.isEmpty) {
      parsedDimensions = {"planner": 80, "sensitive": 75, "explorer": 72, "helper": 72};
    }

    return AssessmentResult(
      mainTrait: mainTraitName,
      description: mainDescription,
      scores: parsedScores,
      confidenceScore: json['confidence'] ?? json['assessment_meta']?['confidence'] ?? 80,
      dimensionScores: parsedDimensions,
      guidelines: json['recommendations'] != null 
          ? List<String>.from(json['recommendations']) 
          : [json['note'] ?? "النتيجة إرشادية وليست تشخيصًا طبيًا."],
    );
  }

  static String _generateTraitDescription(String traitName, int score) {
    switch (traitName.toLowerCase()) {
      case 'focus':
        return score > 50 ? 'يمتلك الطفل قدرة ممتازة على التركيز وإنهاء المهام.' : 'قد يحتاج الطفل لتمارين لزيادة الانتباه.';
      case 'leadership':
        return score > 50 ? 'يظهر مهارات قيادية عالية وقدرة على المبادرة.' : 'يحتاج إلى تعزيز الثقة بالنفس والمبادرة.';
      case 'sociability':
        return score > 50 ? 'طفل اجتماعي للغاية ومحب لتكوين الصداقات.' : 'يميل الطفل إلى الهدوء والاستقلالية الاجتماعية.';
      case 'empathy':
        return 'يقيس مدى تفاعل وفهم الطفل لمشاعر الآخرين ودعمهم الملاحظ بـ $score%.';
      case 'self_control':
        return 'يعكس قدرة الطفل على التحكم في انفعالاته وتنظيم سلوكه اليومي.';
      case 'curiosity':
        return 'يدل على حب الطفل للاكتشاف وطرح الأسئلة والتعلم المستمر.';
      case 'adaptability':
        return 'يقيس مرونة الطفل في التعامل مع التغييرات والمواقف الجديدة.';
      case 'sensitivity':
        return 'يعكس مدى تأثر الطفل بالبيئة المحيطة به واستجابته للمؤثرات.';
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