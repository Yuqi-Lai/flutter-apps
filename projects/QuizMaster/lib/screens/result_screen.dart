import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import 'quiz_screen.dart';
import 'login_screen.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  final bool timedOut;

  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.timedOut,
  });

  double get percentage => (score / totalQuestions) * 100;

  String get resultMessage {
    if (timedOut) {
      return 'Time\'s Up!';
    } else if (percentage >= 80) {
      return 'Excellent!';
    } else if (percentage >= 60) {
      return 'Good Job!';
    } else if (percentage >= 40) {
      return 'Not Bad!';
    } else {
      return 'Keep Practicing!';
    }
  }

  MaterialColor get resultColor {
    if (timedOut) {
      return Colors.red;
    } else if (percentage >= 80) {
      return Colors.green;
    } else if (percentage >= 60) {
      return Colors.blue;
    } else if (percentage >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              resultColor.shade300,
              resultColor.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      timedOut ? Icons.timer_off : Icons.emoji_events,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      resultMessage,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                      if (timedOut)
                      const Text(
                        'Quiz timed out - No score recorded',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'You scored',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    const SizedBox(height: 24),
                      if (!timedOut)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontSize: 80,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'out of $totalQuestions',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 48),
                      ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Take Another Quiz',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: resultColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                      OutlinedButton.icon(
                      onPressed: () async {
                        await FirebaseService().signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

