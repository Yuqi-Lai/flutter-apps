import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String title;
  final double price;
  final String description;
  final List<String> imageUrls;
  final String condition;
  final String contactInfo;
  final String userId;
  final GeoPoint? location;
  final String? locationName;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.condition = '',
    this.contactInfo = '',
    required this.userId,
    this.location,
    this.locationName,
    required this.createdAt,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Handle createdAt - it might be null, a Timestamp, or a DateTime
    DateTime createdAtDate;
    if (data['createdAt'] == null) {
      createdAtDate = DateTime.now();
    } else if (data['createdAt'] is Timestamp) {
      createdAtDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is DateTime) {
      createdAtDate = data['createdAt'] as DateTime;
    } else {
      // Fallback to current time if unknown type
      createdAtDate = DateTime.now();
    }
    
    return Post(
      id: doc.id,
      title: data['title'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      description: data['description'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      condition: data['condition'] ?? '',
      contactInfo: data['contactInfo'] ?? '',
      userId: data['userId'] ?? '',
      location: data['location'] is GeoPoint ? data['location'] as GeoPoint : null,
      locationName: data['locationName'] as String?,
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'price': price,
      'description': description,
      'imageUrls': imageUrls,
      'condition': condition,
      'contactInfo': contactInfo,
      'userId': userId,
      'location': location,
      'locationName': locationName,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

