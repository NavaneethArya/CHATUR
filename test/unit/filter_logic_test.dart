import 'package:flutter_test/flutter_test.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:collection';

void main() {
  group('Skills Filter Logic Tests', () {
    late List<SkillPost> mockSkills;

    setUp(() {
      mockSkills = [
        _createSkillPost(
          id: '1',
          title: 'Plumber Service',
          category: 'Plumber',
          flatPrice: 500,
          rating: 4.5,
          reviewCount: 10,
        ),
        _createSkillPost(
          id: '2',
          title: 'Electrician Service',
          category: 'Electrician',
          perKmPrice: 25,
          rating: 4.8,
          reviewCount: 15,
        ),
        _createSkillPost(
          id: '3',
          title: 'Carpenter Service',
          category: 'Carpenter',
          flatPrice: 800,
          rating: 3.5,
          reviewCount: 5,
        ),
      ];
    });

    test('should filter by category', () {
      final filtered = mockSkills
          .where((skill) => skill.category == 'Plumber')
          .toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.category, equals('Plumber'));
    });

    test('should filter by search query', () {
      final query = 'plumber';
      final filtered = mockSkills
          .where((skill) =>
              skill.title.toLowerCase().contains(query.toLowerCase()) ||
              skill.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.title.toLowerCase(), contains('plumber'));
    });

    test('should filter by price range', () {
      final minPrice = 400;
      final maxPrice = 600;
      final filtered = mockSkills.where((skill) {
        final price = skill.flatPrice ?? skill.perKmPrice ?? 0;
        return price == 0 || (price >= minPrice && price <= maxPrice);
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.flatPrice, equals(500));
    });

    test('should filter verified providers only', () {
      final filtered = mockSkills
          .where((skill) => skill.isVerified)
          .toList();

      expect(filtered.length, equals(2));
      filtered.forEach((skill) {
        expect(skill.isVerified, isTrue);
      });
    });

    test('should filter by status', () {
      final filtered = mockSkills
          .where((skill) => skill.status == 'active')
          .toList();

      expect(filtered.length, equals(3));
    });

    test('should combine multiple filters', () {
      final query = 'plumber';
      final category = 'Plumber';
      final minPrice = 400;
      final maxPrice = 600;

      final filtered = mockSkills.where((skill) {
        final matchesSearch =
            skill.title.toLowerCase().contains(query.toLowerCase()) ||
                skill.category.toLowerCase().contains(query.toLowerCase());
        final matchesCategory = skill.category == category;
        final price = skill.flatPrice ?? skill.perKmPrice ?? 0;
        final matchesPrice =
            price == 0 || (price >= minPrice && price <= maxPrice);

        return matchesSearch && matchesCategory && matchesPrice;
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.category, equals('Plumber'));
    });
  });

  group('Sort Logic Tests', () {
    late List<SkillPost> mockSkills;

    setUp(() {
      mockSkills = [
        _createSkillPost(
          id: '1',
          title: 'Service A',
          flatPrice: 500,
          rating: 4.0,
          bookingCount: 10,
          createdAt: DateTime.now().subtract(Duration(days: 2)),
        ),
        _createSkillPost(
          id: '2',
          title: 'Service B',
          flatPrice: 800,
          rating: 4.8,
          bookingCount: 50,
          createdAt: DateTime.now().subtract(Duration(days: 1)),
        ),
        _createSkillPost(
          id: '3',
          title: 'Service C',
          flatPrice: 300,
          rating: 4.5,
          bookingCount: 30,
          createdAt: DateTime.now(),
        ),
      ];
    });

    test('should sort by most recent', () {
      final sorted = List<SkillPost>.from(mockSkills);
      sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.id, equals('3'));
      expect(sorted.last.id, equals('1'));
    });

    test('should sort by highest rating', () {
      final sorted = List<SkillPost>.from(mockSkills);
      sorted.sort((a, b) => b.rating.compareTo(a.rating));

      expect(sorted.first.rating, equals(4.8));
      expect(sorted.last.rating, equals(4.0));
    });

    test('should sort by price low to high', () {
      final sorted = List<SkillPost>.from(mockSkills);
      sorted.sort((a, b) {
        final priceA = a.flatPrice ?? a.perKmPrice ?? 99999;
        final priceB = b.flatPrice ?? b.perKmPrice ?? 99999;
        return priceA.compareTo(priceB);
      });

      expect(sorted.first.flatPrice, equals(300));
      expect(sorted.last.flatPrice, equals(800));
    });

    test('should sort by most popular (booking count)', () {
      final sorted = List<SkillPost>.from(mockSkills);
      sorted.sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

      expect(sorted.first.bookingCount, equals(50));
      expect(sorted.last.bookingCount, equals(10));
    });
  });
}

// Helper function to create mock SkillPost
SkillPost _createSkillPost({
  required String id,
  String? title,
  String? category,
  int? flatPrice,
  int? perKmPrice,
  double? rating,
  int? reviewCount,
  int? bookingCount,
  DateTime? createdAt,
  bool? verified,
  String? status,
}) {
  final doc = FakeDocumentSnapshot<Map<String, dynamic>>(
    id: id,
    data: () => {
      'userId': 'test-user',
      'skillTitle': title ?? 'Test Service',
      'category': category ?? 'General',
      'flatPrice': flatPrice,
      'perKmPrice': perKmPrice,
      'images': [],
      'address': 'Test Address',
      'coordinates': GeoPoint(12.9716, 77.5946),
      'serviceRadiusMeters': 5000,
      'rating': rating ?? 0.0,
      'reviewCount': reviewCount ?? 0,
      'viewCount': 0,
      'bookingCount': bookingCount ?? 0,
      'status': status ?? 'active',
      'isAtWork': false,
      'verified': verified ?? false,
      'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
    },
  );

  return SkillPost.fromFirestore(doc);
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
  dynamic operator [](Object field) => (data() as Map?)?[field];

  @override
  bool get exists => true;

  @override
  DocumentReference<T> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

