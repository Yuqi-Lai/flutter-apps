import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/question.dart';
import '../models/quiz_result.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled the sign-in
      }
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Load questions from Firestore
  Future<List<Question>> loadQuestions() async {
    try {
      final snapshot = await _firestore.collection('questions').limit(10).get();
      return snapshot.docs.map((doc) {
        return Question.fromFirestore(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Error loading questions: $e');
      return [];
    }
  }
  
  // Save quiz result to Firestore
  Future<void> saveQuizResult(QuizResult result) async {
    try {
      await _firestore.collection('quizResults').add(result.toFirestore());
    } catch (e) {
      print('Error saving quiz result: $e');
    }
  }
  
  // Get user quiz results
  Future<List<QuizResult>> getUserQuizResults(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('quizResults')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return QuizResult.fromFirestore(doc.data());
      }).toList();
    } catch (e) {
      print('Error loading quiz results: $e');
      return [];
    }
  }
}

