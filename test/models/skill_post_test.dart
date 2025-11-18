import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';

void main() {
  group('SkillPost Model Tests', () {
    late DocumentSnapshot<Map<String, dynamic>> mockDoc;

    setUp(() {
      mockDoc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Plumbing Service',
        'category': 'Plumber',
        'description': 'Professional plumbing services',
        'flatPrice': 500,
        'perKmPrice': null,
        'images': ['https://example.com/image1.jpg'],
        'address': '123 Main St',
        'coordinates': GeoPoint(12.9716, 77.5946),
        'serviceRadiusMeters': 5000,
        'rating': 4.5,
        'reviewCount': 10,
        'viewCount': 100,
        'bookingCount': 50,
        'status': 'active',
        'isAtWork': true,
        'verified': true,
        'createdAt': Timestamp.now(),
        'profile': {'phone': '1234567890'},
      });
    });

    test('should create SkillPost from Firestore document', () {
      final skill = SkillPost.fromFirestore(mockDoc);

      expect(skill.id, equals(mockDoc.id));
      expect(skill.userId, equals('user123'));
      expect(skill.title, equals('Plumbing Service'));
      expect(skill.category, equals('Plumber'));
      expect(skill.flatPrice, equals(500));
      expect(skill.perKmPrice, isNull);
      expect(skill.imageUrls.length, equals(1));
      expect(skill.rating, equals(4.5));
      expect(skill.verified, isTrue);
    });

    test('should return correct price display for flat price', () {
      final skill = SkillPost.fromFirestore(mockDoc);
      expect(skill.priceDisplay, equals('₹500'));
    });

    test('should return correct price display for perKm price', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Service',
        'category': 'General',
        'perKmPrice': 25,
        'flatPrice': null,
        'images': [],
        'coordinates': GeoPoint(0, 0),
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.priceDisplay, equals('₹25/km'));
    });

    test('should return Negotiable when no price set', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Service',
        'category': 'General',
        'perKmPrice': null,
        'flatPrice': null,
        'images': [],
        'coordinates': GeoPoint(0, 0),
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.priceDisplay, equals('Negotiable'));
    });

    test('should return correct time ago for recent post', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Service',
        'category': 'General',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 2))),
        'images': [],
        'coordinates': GeoPoint(0, 0),
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.timeAgo, equals('2h ago'));
    });

    test('should return verified status correctly', () {
      final skill = SkillPost.fromFirestore(mockDoc);
      expect(skill.isVerified, isTrue);
    });

    test('should return verified status based on rating and reviews', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Service',
        'category': 'General',
        'rating': 4.8,
        'reviewCount': 15,
        'verified': false,
        'images': [],
        'coordinates': GeoPoint(0, 0),
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.isVerified, isTrue);
    });

    test('should handle missing phone number', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': 'Service',
        'category': 'General',
        'images': [],
        'coordinates': GeoPoint(0, 0),
        'profile': null,
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.phoneNumber, isNull);
    });

    test('should handle default values for missing fields', () {
      final doc = _createMockDocument({
        'userId': 'user123',
        'skillTitle': null,
        'category': null,
      });
      final skill = SkillPost.fromFirestore(doc);
      expect(skill.title, equals('Service'));
      expect(skill.category, equals('General'));
      expect(skill.description, equals(''));
      expect(skill.rating, equals(0.0));
      expect(skill.reviewCount, equals(0));
    });
  });
}

// Helper function to create mock document
DocumentSnapshot<Map<String, dynamic>> _createMockDocument(
  Map<String, dynamic> data,
) {
  return FakeDocumentSnapshot<Map<String, dynamic>>(
    id: 'test-doc-${DateTime.now().millisecondsSinceEpoch}',
    data: () => data,
  );
}

// Fake DocumentSnapshot for testing
class FakeDocumentSnapshot<T extends Object?> implements DocumentSnapshot<T> {
  final String id;
  final T Function() _data;

  FakeDocumentSnapshot({required this.id, required T Function() data})
      : _data = data;

  @override
  T? data() => _data();

  @override
  dynamic get(Object field) => (data() as Map?)?[field];

  @override
  bool get exists => true;

  @override
  DocumentReference<T> get reference => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => (data() as Map?)?[field];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

