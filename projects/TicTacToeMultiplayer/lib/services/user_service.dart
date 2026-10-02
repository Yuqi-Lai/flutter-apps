import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or update user document in Firestore users collection
  static Future<void> createOrUpdateUser(User user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSignIn': FieldValue.serverTimestamp(),
      };

      // Check if user exists
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        // Update existing user
        await userDoc.update({
          'lastSignIn': FieldValue.serverTimestamp(),
          'displayName': user.displayName,
          'photoURL': user.photoURL,
        });
      } else {
        // Create new user with initial stats
        userData['createdAt'] = FieldValue.serverTimestamp();
        userData['gamesPlayed'] = 0;
        userData['gamesWon'] = 0;
        userData['gamesLost'] = 0;
        userData['gamesDraw'] = 0;
        
        await userDoc.set(userData);
      }
    } catch (e) {
      print('Error creating/updating user: $e');
    }
  }

  /// Update user game statistics
  static Future<void> updateUserStats(String userId, {
    required bool isWin,
    required bool isDraw,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      
      Map<String, dynamic> updates = {
        'gamesPlayed': FieldValue.increment(1),
      };

      if (isDraw) {
        updates['gamesDraw'] = FieldValue.increment(1);
      } else if (isWin) {
        updates['gamesWon'] = FieldValue.increment(1);
      } else {
        updates['gamesLost'] = FieldValue.increment(1);
      }

      await userDoc.update(updates);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  /// Get user statistics
  static Future<Map<String, dynamic>?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }
}

