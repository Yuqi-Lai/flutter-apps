import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoRecord {
  final String id;
  final String userId;
  final String userEmail;
  final String fileName;
  final String storageUrl;
  final bool hasFace;
  final DateTime timestamp;

  PhotoRecord({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.fileName,
    required this.storageUrl,
    required this.hasFace,
    required this.timestamp,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'fileName': fileName,
      'storageUrl': storageUrl,
      'hasFace': hasFace,
      'timestamp': timestamp,
    };
  }

  // Create from Firestore document
  factory PhotoRecord.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PhotoRecord(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      fileName: data['fileName'] ?? '',
      storageUrl: data['storageUrl'] ?? '',
      hasFace: data['hasFace'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Create from Map
  factory PhotoRecord.fromMap(String id, Map<String, dynamic> data) {
    return PhotoRecord(
      id: id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      fileName: data['fileName'] ?? '',
      storageUrl: data['storageUrl'] ?? '',
      hasFace: data['hasFace'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}

