import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { eventCreated, eventUpdated, eventDeleted }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      type: _typeFromString(data['type'] ?? 'eventCreated'),
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      eventId: data['eventId'] ?? '',
      eventTitle: data['eventTitle'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      imageUrl: data['imageUrl'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': _typeToString(type),
      'title': title,
      'message': message,
      'eventId': eventId,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'imageUrl': imageUrl,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'eventCreated':
        return NotificationType.eventCreated;
      case 'eventUpdated':
        return NotificationType.eventUpdated;
      case 'eventDeleted':
        return NotificationType.eventDeleted;
      default:
        return NotificationType.eventCreated;
    }
  }

  static String _typeToString(NotificationType type) {
    switch (type) {
      case NotificationType.eventCreated:
        return 'eventCreated';
      case NotificationType.eventUpdated:
        return 'eventUpdated';
      case NotificationType.eventDeleted:
        return 'eventDeleted';
    }
  }

  // Helper to get icon based on type
  String get iconEmoji {
    switch (type) {
      case NotificationType.eventCreated:
        return '🎉';
      case NotificationType.eventUpdated:
        return '📝';
      case NotificationType.eventDeleted:
        return '🗑️';
    }
  }
}
