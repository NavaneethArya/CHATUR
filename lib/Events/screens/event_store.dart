import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// KEEP YOUR EXISTING Event CLASS (for backward compatibility)
class Event {
  final String heading;
  final String description;
  final String? imageUrl;

  Event({required this.heading, required this.description, this.imageUrl});

  // Convert to Firebase format
  Map<String, dynamic> toFirestore() {
    return {
      'heading': heading,
      'description': description,
      'imageUrl': imageUrl,
      'createdBy': 'Panchayat Member', // Default for migration
      'createdByEmail': 'admin@chatur.com',
      'createdAt': FieldValue.serverTimestamp(),
      'likes': 0,
      'likedBy': [],
      'comments': [],
    };
  }

  // Create from Firebase
  factory Event.fromFirestore(Map<String, dynamic> data) {
    return Event(
      heading: data['heading'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
    );
  }
}

// UPDATED EventStore with Firebase support
class EventStore {
  static final EventStore instance = EventStore._internal();
  EventStore._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Keep in-memory cache for offline support
  final Map<DateTime, List<Event>> _localCache = {};
  bool _useFirebase = true; // Toggle for testing

  // ============================================
  // EXISTING METHODS (Keep working as before)
  // ============================================

  void addEvent(DateTime date, Event event) {
    if (_useFirebase) {
      _addToFirebase(date, event);
    } else {
      _addToLocalCache(date, event);
    }
  }

  List<Event> getEventsByDate(DateTime date) {
    // Return from local cache for now (we'll add Firebase stream later)
    final dateKey = _normalizeDate(date);
    return _localCache[dateKey] ?? [];
  }

  void deleteEvent(DateTime date, Event event) {
    if (_useFirebase) {
      _deleteFromFirebase(date, event);
    } else {
      _deleteFromLocalCache(date, event);
    }
  }

  Map<DateTime, List<Event>> allEvents() {
    return _localCache;
  }

  // ============================================
  // NEW FIREBASE METHODS (Added functionality)
  // ============================================

  Future<void> _addToFirebase(DateTime date, Event event) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      await _firestore
          .collection('events')
          .doc(dateKey)
          .collection('eventsList')
          .add(event.toFirestore());

      // Also update local cache
      _addToLocalCache(date, event);
    } catch (e) {
      print('Error adding to Firebase: $e');
      // Fallback to local cache
      _addToLocalCache(date, event);
    }
  }

  Future<void> _deleteFromFirebase(DateTime date, Event event) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final querySnapshot =
          await _firestore
              .collection('events')
              .doc(dateKey)
              .collection('eventsList')
              .where('heading', isEqualTo: event.heading)
              .where('description', isEqualTo: event.description)
              .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      _deleteFromLocalCache(date, event);
    } catch (e) {
      print('Error deleting from Firebase: $e');
      _deleteFromLocalCache(date, event);
    }
  }

  // Load events from Firebase
  Future<void> loadEventsFromFirebase(DateTime date) async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final snapshot =
          await _firestore
              .collection('events')
              .doc(dateKey)
              .collection('eventsList')
              .get();

      final events =
          snapshot.docs.map((doc) => Event.fromFirestore(doc.data())).toList();

      final normalizedDate = _normalizeDate(date);
      _localCache[normalizedDate] = events;
    } catch (e) {
      print('Error loading from Firebase: $e');
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  void _addToLocalCache(DateTime date, Event event) {
    final dateKey = _normalizeDate(date);
    _localCache[dateKey] = (_localCache[dateKey] ?? [])..add(event);
  }

  void _deleteFromLocalCache(DateTime date, Event event) {
    final dateKey = _normalizeDate(date);
    _localCache[dateKey]?.remove(event);
    if (_localCache[dateKey]?.isEmpty ?? false) {
      _localCache.remove(dateKey);
    }
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Toggle Firebase usage (for testing)
  void setUseFirebase(bool value) {
    _useFirebase = value;
  }
}
