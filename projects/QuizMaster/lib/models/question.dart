enum QuestionType {
  multipleChoiceSingle,
  trueFalse,
  multipleChoiceMultiple,
}

class Question {
  final String id;
  final String question;
  final QuestionType type;
  final List<String> options;
  final List<String> correctAnswers; 
  
  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswers,
  });
  
  factory Question.fromFirestore(Map<String, dynamic> data, String id) {
    String typeString = data['type'] as String;
    QuestionType type;
    
    switch (typeString) {
      case 'multipleChoiceSingle':
        type = QuestionType.multipleChoiceSingle;
        break;
      case 'trueFalse':
        type = QuestionType.trueFalse;
        break;
      case 'multipleChoiceMultiple':
        type = QuestionType.multipleChoiceMultiple;
        break;
      default:
        type = QuestionType.multipleChoiceSingle;
    }
    
    return Question(
      id: id,
      question: data['question'] as String,
      type: type,
      options: List<String>.from(data['options'] as List),
      correctAnswers: List<String>.from(data['correctAnswers'] as List),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    String typeString;
    switch (type) {
      case QuestionType.multipleChoiceSingle:
        typeString = 'multipleChoiceSingle';
        break;
      case QuestionType.trueFalse:
        typeString = 'trueFalse';
        break;
      case QuestionType.multipleChoiceMultiple:
        typeString = 'multipleChoiceMultiple';
        break;
    }
    
    return {
      'question': question,
      'type': typeString,
      'options': options,
      'correctAnswers': correctAnswers,
    };
  }
}

