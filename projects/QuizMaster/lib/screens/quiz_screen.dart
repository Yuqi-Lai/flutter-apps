import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';
import '../services/firebase_service.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isLoading = true;
  
  // Timer
  Timer? _timer;
  int _secondsRemaining = 60;
  
  // Selected answers
  String? _selectedSingleAnswer;
  Set<String> _selectedMultipleAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final questions = await _firebaseService.loadQuestions();
    if (questions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions available. Please add questions to Firestore.')),
      );
      Navigator.of(context).pop();
      return;
    }
    
    // Shuffle questions for random order
    questions.shuffle();
    
    setState(() {
      _questions = questions;
      _isLoading = false;
    });
    
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    _timer?.cancel();
    _saveAndNavigateToResults(timedOut: true);
  }

  void _checkAnswer() {
    final currentQuestion = _questions[_currentQuestionIndex];
    bool isCorrect = false;
    
    if (currentQuestion.type == QuestionType.multipleChoiceMultiple) {
      // Check if selected answers match correct answers
      if (_selectedMultipleAnswers.length == currentQuestion.correctAnswers.length &&
          _selectedMultipleAnswers.every((answer) => currentQuestion.correctAnswers.contains(answer))) {
        isCorrect = true;
      }
    } else {
      // Single answer or True/False
      if (_selectedSingleAnswer != null &&
          currentQuestion.correctAnswers.contains(_selectedSingleAnswer)) {
        isCorrect = true;
      }
    }
    
    if (isCorrect) {
      _score++;
    }
    
    // Move to next question or finish
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedSingleAnswer = null;
        _selectedMultipleAnswers = {};
      });
    } else {
      _saveAndNavigateToResults(timedOut: false);
    }
  }

  Future<void> _saveAndNavigateToResults({required bool timedOut}) async {
    _timer?.cancel();
    
    final result = QuizResult(
      userId: _firebaseService.currentUser!.uid,
      score: timedOut ? 0 : _score,
      totalQuestions: _questions.length,
      timestamp: DateTime.now(),
      timedOut: timedOut,
    );
    
    await _firebaseService.saveQuizResult(result);
    
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          score: timedOut ? 0 : _score,
          totalQuestions: _questions.length,
          timedOut: timedOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildQuestionWidget(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoiceSingle:
      case QuestionType.trueFalse:
        return _buildSingleChoiceQuestion(question);
      case QuestionType.multipleChoiceMultiple:
        return _buildMultipleChoiceQuestion(question);
    }
  }

  Widget _buildSingleChoiceQuestion(Question question) {
    return Column(
      children: question.options.map((option) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSingleAnswer = option;
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _selectedSingleAnswer == option
                    ? Colors.green.shade100
                    : Colors.white,
                border: Border.all(
                  color: _selectedSingleAnswer == option
                      ? Colors.green.shade700
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedSingleAnswer == option
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _selectedSingleAnswer == option
                        ? Colors.green.shade700
                        : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: _selectedSingleAnswer == option
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMultipleChoiceQuestion(Question question) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Select all correct answers',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
        ...question.options.map((option) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (_selectedMultipleAnswers.contains(option)) {
                    _selectedMultipleAnswers.remove(option);
                  } else {
                    _selectedMultipleAnswers.add(option);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedMultipleAnswers.contains(option)
                      ? Colors.green.shade100
                      : Colors.white,
                  border: Border.all(
                    color: _selectedMultipleAnswers.contains(option)
                        ? Colors.green.shade700
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedMultipleAnswers.contains(option)
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: _selectedMultipleAnswers.contains(option)
                          ? Colors.green.shade700
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: _selectedMultipleAnswers.contains(option)
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  bool _canSubmitAnswer() {
    final currentQuestion = _questions[_currentQuestionIndex];
    if (currentQuestion.type == QuestionType.multipleChoiceMultiple) {
      return _selectedMultipleAnswers.isNotEmpty;
    } else {
      return _selectedSingleAnswer != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _secondsRemaining <= 10 ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_secondsRemaining}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentQuestionIndex + 1) / _questions.length,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
              const SizedBox(height: 16),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Question
              Text(
                currentQuestion.question,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              // Answer options
              Expanded(
                child: SingleChildScrollView(
                  child: _buildQuestionWidget(currentQuestion),
                ),
              ),
              // Submit button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmitAnswer() ? _checkAnswer : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    _currentQuestionIndex < _questions.length - 1
                        ? 'Next Question'
                        : 'Finish Quiz',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

