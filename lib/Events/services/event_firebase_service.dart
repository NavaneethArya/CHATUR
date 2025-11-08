// ============================================
// COMPLETE OPTIMIZED EVENT FIREBASE SERVICE
// Location: lib/Events/services/event_firebase_service.dart
// ============================================

import 'package:chatur_frontend/Events/models/event_model.dart';
import 'package:chatur_frontend/Events/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventFirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference get _eventsCollection =>
      _firestore.collection('events');

  // Cache to store loaded events
  static List<EventModel>? _cachedEvents;
  static DateTime? _lastFetchTime;

  // ============================================
  // OPTIMIZED: GET RECENT EVENTS (MUCH FASTER)
  // Fetches events in parallel with caching
  // ============================================

  static Future<List<EventModel>> getRecentEvents({
    int daysBefore = 7,
    int daysAfter = 21,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and fresh (less than 2 minutes old)
    if (!forceRefresh &&
        _cachedEvents != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < Duration(minutes: 2)) {
      print('📦 Returning cached events (${_cachedEvents!.length} events)');
      return _cachedEvents!;
    }

    final startTime = DateTime.now();
    print('🔄 Fetching events from Firebase...');

    final today = DateTime.now();
    final startDate = today.subtract(Duration(days: daysBefore));
    final endDate = today.add(Duration(days: daysAfter));

    List<EventModel> allEvents = [];
    List<Future<void>> fetchTasks = [];

    // Fetch dates in parallel for better performance
    for (
      DateTime date = startDate;
      date.isBefore(endDate);
      date = date.add(Duration(days: 1))
    ) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      // Add to parallel fetch list
      fetchTasks.add(
        _eventsCollection
            .doc(dateKey)
            .collection('eventsList')
            .get()
            .then((snapshot) {
              for (var doc in snapshot.docs) {
                try {
                  allEvents.add(EventModel.fromFirestore(doc));
                } catch (e) {
                  print('❌ Error parsing event: $e');
                }
              }
            })
            .catchError((e) {
              // Date might not exist, silently continue
            }),
      );
    }

    // Wait for all fetches to complete (parallel execution)
    await Future.wait(fetchTasks);

    // Sort by date (upcoming events first)
    allEvents.sort((a, b) => a.eventDate.compareTo(b.eventDate));

    // Cache the results
    _cachedEvents = allEvents;
    _lastFetchTime = DateTime.now();

    final duration = DateTime.now().difference(startTime);
    print(
      '✅ Loaded ${allEvents.length} events in ${duration.inMilliseconds}ms',
    );

    return allEvents;
  }

  // ============================================
  // GET EVENTS FOR SPECIFIC DATE (Real-time)
  // Use this in calendar view
  // ============================================

  static Stream<List<EventModel>> getEventsForDate(DateTime date) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    return _eventsCollection
        .doc(dateKey)
        .collection('eventsList')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc))
              .toList();
        });
  }

  // ============================================
  // GET EVENTS FOR MONTH (For calendar view)
  // ============================================

  static Future<Map<DateTime, List<EventModel>>> getEventsForMonth(
    DateTime month,
  ) async {
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    Map<DateTime, List<EventModel>> eventsByDate = {};
    List<Future<void>> fetchTasks = [];

    for (
      DateTime date = startDate;
      date.isBefore(endDate.add(Duration(days: 1)));
      date = date.add(Duration(days: 1))
    ) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final normalizedDate = DateTime(date.year, date.month, date.day);

      fetchTasks.add(
        _eventsCollection
            .doc(dateKey)
            .collection('eventsList')
            .get()
            .then((snapshot) {
              if (snapshot.docs.isNotEmpty) {
                eventsByDate[normalizedDate] =
                    snapshot.docs
                        .map((doc) => EventModel.fromFirestore(doc))
                        .toList();
              }
            })
            .catchError((e) {
              // Date might not exist
            }),
      );
    }

    await Future.wait(fetchTasks);
    return eventsByDate;
  }

  // ============================================
  // ADD NEW EVENT
  // ============================================

  static Future<void> addEvent(EventModel event) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.eventDate);
      final docRef = await _eventsCollection
          .doc(dateKey)
          .collection('eventsList')
          .add(event.toFirestore());

      // Create notification with the new event ID
      final eventWithId = EventModel(
        id: docRef.id,
        heading: event.heading,
        description: event.description,
        imageUrl: event.imageUrl,
        createdBy: event.createdBy,
        createdByEmail: event.createdByEmail,
        eventDate: event.eventDate,
        location: event.location,
        locationName: event.locationName,
        createdAt: event.createdAt,
        likes: event.likes,
        likedBy: event.likedBy,
        comments: event.comments,
      );

      // TRIGGER NOTIFICATION
      await NotificationService.notifyEventCreated(eventWithId);

      // Invalidate cache
      _cachedEvents = null;

      print('✅ Event added successfully for date: $dateKey');
    } catch (e) {
      print('❌ Error adding event: $e');
      throw Exception('Failed to add event: $e');
    }
  }

  // ============================================
  // UPDATE EVENT
  // ============================================

  static Future<void> updateEvent(
    DateTime eventDate,
    String eventId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(eventDate);
      await _eventsCollection
          .doc(dateKey)
          .collection('eventsList')
          .doc(eventId)
          .update(updates);

      // Get updated event data for notification
      final doc =
          await _eventsCollection
              .doc(dateKey)
              .collection('eventsList')
              .doc(eventId)
              .get();

      if (doc.exists) {
        final updatedEvent = EventModel.fromFirestore(doc);

        // TRIGGER NOTIFICATION
        await NotificationService.notifyEventUpdated(updatedEvent);
      }

      // Invalidate cache
      _cachedEvents = null;

      print('✅ Event updated successfully');
    } catch (e) {
      print('❌ Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  // ============================================
  // DELETE EVENT
  // ============================================

  static Future<void> deleteEvent(DateTime eventDate, String eventId) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(eventDate);

      // Get event data before deleting for notification
      final doc =
          await _eventsCollection
              .doc(dateKey)
              .collection('eventsList')
              .doc(eventId)
              .get();

      String eventTitle = 'Unknown Event';
      String deletedBy = 'Panchayat Member';

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        eventTitle = data['heading'] ?? 'Unknown Event';
        deletedBy = data['createdBy'] ?? 'Panchayat Member';
      }

      // Delete the event
      await _eventsCollection
          .doc(dateKey)
          .collection('eventsList')
          .doc(eventId)
          .delete();

      // TRIGGER NOTIFICATION
      await NotificationService.notifyEventDeleted(
        eventTitle: eventTitle,
        deletedBy: deletedBy,
        eventDate: eventDate,
      );

      // Invalidate cache
      _cachedEvents = null;

      print('✅ Event deleted successfully');
    } catch (e) {
      print('❌ Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  // ============================================
  // LIKE / UNLIKE EVENT
  // ============================================

  static Future<void> toggleLike(
    DateTime eventDate,
    String eventId,
    String userEmail,
  ) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(eventDate);
      final docRef = _eventsCollection
          .doc(dateKey)
          .collection('eventsList')
          .doc(eventId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final likedBy = List<String>.from(data['likedBy'] ?? []);
        final likes = data['likes'] ?? 0;

        if (likedBy.contains(userEmail)) {
          // Unlike
          likedBy.remove(userEmail);
          transaction.update(docRef, {
            'likes': likes > 0 ? likes - 1 : 0,
            'likedBy': likedBy,
          });
        } else {
          // Like
          likedBy.add(userEmail);
          transaction.update(docRef, {'likes': likes + 1, 'likedBy': likedBy});
        }
      });

      // Invalidate cache to show updated likes
      _cachedEvents = null;

      print('✅ Like toggled successfully');
    } catch (e) {
      print('❌ Error toggling like: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }

  // ============================================
  // ADD COMMENT
  // ============================================

  static Future<void> addComment(
    DateTime eventDate,
    String eventId,
    String userName,
    String userEmail,
    String commentText,
  ) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(eventDate);
      final docRef = _eventsCollection
          .doc(dateKey)
          .collection('eventsList')
          .doc(eventId);

      final comment = {
        'userName': userName,
        'userEmail': userEmail,
        'text': commentText,
        'timestamp': Timestamp.now(),
      };

      await docRef.update({
        'comments': FieldValue.arrayUnion([comment]),
      });

      // Invalidate cache to show new comment
      _cachedEvents = null;

      print('✅ Comment added successfully');
    } catch (e) {
      print('❌ Error adding comment: $e');
      throw Exception('Failed to add comment: $e');
    }
  }

  // ============================================
  // CLEAR CACHE (Call on logout or manual refresh)
  // ============================================

  static void clearCache() {
    _cachedEvents = null;
    _lastFetchTime = null;
    print('🗑️ Cache cleared');
  }

  // ============================================
  // GET CACHE INFO (For debugging)
  // ============================================

  static String getCacheInfo() {
    if (_cachedEvents == null) {
      return 'Cache: Empty';
    }

    final age = DateTime.now().difference(_lastFetchTime!);
    return 'Cache: ${_cachedEvents!.length} events, ${age.inSeconds}s old';
  }
}
