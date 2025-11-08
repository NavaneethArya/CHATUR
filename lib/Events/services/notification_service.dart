import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatur_frontend/Events/models/notification_model.dart';
import 'package:chatur_frontend/Events/models/event_model.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to notifications collection
  static CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  // Reference to event notifications subcollection
  static CollectionReference get _eventNotificationsCollection =>
      _notificationsCollection.doc('event_notifications').collection('items');

  // ============================================
  // CREATE NOTIFICATION WHEN EVENT IS CREATED
  // ============================================
  static Future<void> notifyEventCreated(EventModel event) async {
    try {
      final notification = NotificationModel(
        id: '',
        type: NotificationType.eventCreated,
        title: 'New Event Created! 🎉',
        message: '${event.createdBy} created "${event.heading}"',
        eventId: event.id,
        eventTitle: event.heading,
        eventDate: event.eventDate,
        imageUrl: event.imageUrl,
        createdBy: event.createdBy,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _eventNotificationsCollection.add(notification.toFirestore());
      print('✅ Notification created for new event: ${event.heading}');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // ============================================
  // CREATE NOTIFICATION WHEN EVENT IS UPDATED
  // ============================================
  static Future<void> notifyEventUpdated(EventModel event) async {
    try {
      final notification = NotificationModel(
        id: '',
        type: NotificationType.eventUpdated,
        title: 'Event Updated 📝',
        message: '${event.createdBy} updated "${event.heading}"',
        eventId: event.id,
        eventTitle: event.heading,
        eventDate: event.eventDate,
        imageUrl: event.imageUrl,
        createdBy: event.createdBy,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _eventNotificationsCollection.add(notification.toFirestore());
      print('✅ Notification created for updated event: ${event.heading}');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // ============================================
  // CREATE NOTIFICATION WHEN EVENT IS DELETED
  // ============================================
  static Future<void> notifyEventDeleted({
    required String eventTitle,
    required String deletedBy,
    required DateTime eventDate,
  }) async {
    try {
      final notification = NotificationModel(
        id: '',
        type: NotificationType.eventDeleted,
        title: 'Event Cancelled 🗑️',
        message: '$deletedBy cancelled "$eventTitle"',
        eventId: '',
        eventTitle: eventTitle,
        eventDate: eventDate,
        imageUrl: null,
        createdBy: deletedBy,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _eventNotificationsCollection.add(notification.toFirestore());
      print('✅ Notification created for deleted event: $eventTitle');
    } catch (e) {
      print('❌ Error creating notification: $e');
    }
  }

  // ============================================
  // GET ALL NOTIFICATIONS (REAL-TIME STREAM)
  // ============================================
  static Stream<List<NotificationModel>> getNotificationsStream() {
    return _eventNotificationsCollection
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to last 50 notifications
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
        });
  }

  // ============================================
  // GET UNREAD NOTIFICATIONS COUNT (REAL-TIME)
  // ============================================
  static Stream<int> getUnreadCountStream() {
    return _eventNotificationsCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // ============================================
  // MARK NOTIFICATION AS READ
  // ============================================
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _eventNotificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  // ============================================
  // MARK ALL NOTIFICATIONS AS READ
  // ============================================
  static Future<void> markAllAsRead() async {
    try {
      final unreadDocs =
          await _eventNotificationsCollection
              .where('isRead', isEqualTo: false)
              .get();

      final batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      print('✅ All notifications marked as read');
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  // ============================================
  // DELETE NOTIFICATION
  // ============================================
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _eventNotificationsCollection.doc(notificationId).delete();
      print('✅ Notification deleted');
    } catch (e) {
      print('❌ Error deleting notification: $e');
    }
  }

  // ============================================
  // DELETE OLD NOTIFICATIONS (OLDER THAN 30 DAYS)
  // ============================================
  static Future<void> deleteOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final oldDocs =
          await _eventNotificationsCollection
              .where('createdAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
              .get();

      final batch = _firestore.batch();
      for (var doc in oldDocs.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('✅ Old notifications deleted');
    } catch (e) {
      print('❌ Error deleting old notifications: $e');
    }
  }

  // ============================================
  // GET NOTIFICATIONS FOR SPECIFIC EVENT
  // ============================================
  static Future<List<NotificationModel>> getNotificationsForEvent(
    String eventId,
  ) async {
    try {
      final snapshot =
          await _eventNotificationsCollection
              .where('eventId', isEqualTo: eventId)
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('❌ Error getting event notifications: $e');
      return [];
    }
  }
}
