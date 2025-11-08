import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String heading;
  final String description;
  final String? imageUrl;
  final String createdBy;
  final String createdByEmail;
  final DateTime eventDate;
  final GeoPoint? location; // IMPORTANT: Must be nullable with ?
  final String? locationName; // IMPORTANT: Must be nullable with ?
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;
  final List<Comment> comments;

  EventModel({
    required this.id,
    required this.heading,
    required this.description,
    this.imageUrl,
    required this.createdBy,
    required this.createdByEmail,
    required this.eventDate,
    this.location, // Optional - can be null
    this.locationName, // Optional - can be null
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
    this.comments = const [],
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      heading: data['heading'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? 'Unknown',
      createdByEmail: data['createdByEmail'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      location: data['location'] as GeoPoint?, // Can be null
      locationName: data['locationName'], // Can be null
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      comments: (data['comments'] as List?)
              ?.map((c) => Comment.fromMap(c))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'heading': heading,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdByEmail': createdByEmail,
      'eventDate': Timestamp.fromDate(eventDate),
      'location': location, // Can be null
      'locationName': locationName, // Can be null
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likedBy': likedBy,
      'comments': comments.map((c) => c.toMap()).toList(),
    };
  }
}

class Comment {
  final String userName;
  final String userEmail;
  final String text;
  final DateTime timestamp;

  Comment({
    required this.userName,
    required this.userEmail,
    required this.text,
    required this.timestamp,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userEmail': userEmail,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}