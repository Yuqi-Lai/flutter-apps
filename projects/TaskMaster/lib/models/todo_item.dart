class TodoItem {
  final String id;
  String title;
  String description;
  String address;
  double? latitude;
  double? longitude;
  bool isCompleted;
  DateTime createdAt;
  DateTime? dueDate;
  String? imageUrl;
  String userId;

  TodoItem({
    required this.id,
    required this.title,
    required this.userId,
    this.description = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.imageUrl,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'imageUrl': imageUrl,
      'userId': userId,
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      title: json['title'],
      userId: json['userId'] ?? '',
      description: json['description'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude'],
      longitude: json['longitude'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      dueDate: json['dueDate'] != null 
          ? DateTime.parse(json['dueDate']) 
          : null,
      imageUrl: json['imageUrl'],
    );
  }

  TodoItem copyWith({
    String? title,
    String? description,
    String? address,
    double? latitude,
    double? longitude,
    bool? isCompleted,
    DateTime? dueDate,
    String? imageUrl,
  }) {
    return TodoItem(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
  
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }
}

