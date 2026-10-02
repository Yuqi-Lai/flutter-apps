import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/firestore_service.dart';

class FakeUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;

  FakeUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
  });
}

class AuthProvider with ChangeNotifier {
  FakeUser? _user;
  bool _isLoading = false;

  FakeUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> _createSampleTodos(String userId) async {
    try {
      final todos = await FirestoreService.getTodos(userId);
      if (todos.isEmpty) {
        final sampleTodos = [
          TodoItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_1',
            userId: userId,
            title: 'Pick up bread from Costco',
            description: 'Get whole wheat bread and milk for the week',
            address: '370 D\'Onofrio Drive, Madison, WI 53719',
            latitude: 43.0374,
            longitude: -89.5123,
            dueDate: DateTime.now().add(const Duration(days: 2)),
          ),
          TodoItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_2',
            userId: userId,
            title: 'Team meeting downtown',
            description: 'Quarterly review meeting with team',
            address: '1 Market St, San Francisco, CA 94105',
            latitude: 37.7941,
            longitude: -122.3951,
            dueDate: DateTime.now().add(const Duration(days: 5)),
          ),
          TodoItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_3',
            userId: userId,
            title: 'Grocery shopping at Whole Foods',
            description: 'Buy organic vegetables and fruits',
            address: '399 4th St, San Francisco, CA 94107',
            latitude: 37.7808,
            longitude: -122.3995,
            dueDate: DateTime.now().add(const Duration(days: 1)),
          ),
          TodoItem(
            id: '${DateTime.now().millisecondsSinceEpoch}_4',
            userId: userId,
            title: 'Visit Boston Public Library',
            description: 'Return books and get new ones',
            address: '700 Boylston St, Boston, MA 02116',
            latitude: 42.3493,
            longitude: -71.0776,
            dueDate: DateTime.now().add(const Duration(days: 3)),
          ),
        ];

        await FirestoreService.batchAddTodos(sampleTodos);
      }
    } catch (e) {
      // Ignore errors in sample data creation
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    _user = FakeUser(
      uid: 'demo_user',
      email: 'user@gmail.com',
      displayName: 'Demo User',
      photoURL: null,
    );
    
    await _createSampleTodos(_user!.uid);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(seconds: 1));
    
    _user = FakeUser(
      uid: 'demo_user',
      email: email,
      displayName: email.split('@')[0],
      photoURL: null,
    );
    
    await _createSampleTodos(_user!.uid);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await signInWithEmail(email, password);
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _user = null;
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await Future.delayed(const Duration(seconds: 1));
  }
}

