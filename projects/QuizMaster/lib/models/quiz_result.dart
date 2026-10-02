class QuizResult {
  final String userId;
  final int score;
  final int totalQuestions;
  final DateTime timestamp;
  final bool timedOut;
  
  QuizResult({
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
    required this.timedOut,
  });
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp.toIso8601String(),
      'timedOut': timedOut,
    };
  }
  
  factory QuizResult.fromFirestore(Map<String, dynamic> data) {
    return QuizResult(
      userId: data['userId'] as String,
      score: data['score'] as int,
      totalQuestions: data['totalQuestions'] as int,
      timestamp: DateTime.parse(data['timestamp'] as String),
      timedOut: data['timedOut'] as bool,
    );
  }
}

