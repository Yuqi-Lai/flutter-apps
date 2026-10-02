import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/photo_record.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _photosCollection = 'photos';

  // Write photo record to Firestore
  Future<void> savePhotoRecord({
    required String userId,
    required String userEmail,
    required String fileName,
    required String storageUrl,
    required bool hasFace,
  }) async {
    try {
      await _firestore.collection(_photosCollection).add({
        'userId': userId,
        'userEmail': userEmail,
        'fileName': fileName,
        'storageUrl': storageUrl,
        'hasFace': hasFace,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save photo record: $e');
    }
  }

  // Get all photos for a user
  Stream<List<PhotoRecord>> getUserPhotos(String userId) {
    return _firestore
        .collection(_photosCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PhotoRecord.fromFirestore(doc);
      }).toList();
    });
  }

  // Get all photos (for admin view)
  Stream<List<PhotoRecord>> getAllPhotos() {
    return _firestore
        .collection(_photosCollection)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PhotoRecord.fromFirestore(doc);
      }).toList();
    });
  }

  // Delete a photo record
  Future<void> deletePhotoRecord(String photoId) async {
    try {
      await _firestore.collection(_photosCollection).doc(photoId).delete();
    } catch (e) {
      throw Exception('Failed to delete photo record: $e');
    }
  }

  // Get photo count for user
  Future<int> getUserPhotoCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_photosCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get photo count: $e');
    }
  }

  // Get photos with faces
  Stream<List<PhotoRecord>> getPhotosWithFaces(String userId) {
    return _firestore
        .collection(_photosCollection)
        .where('userId', isEqualTo: userId)
        .where('hasFace', isEqualTo: true)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PhotoRecord.fromFirestore(doc);
      }).toList();
    });
  }
}

