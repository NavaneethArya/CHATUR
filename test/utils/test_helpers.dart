import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';

/// Helper class for test utilities
class TestHelpers {
  /// Creates a mock SkillPost with default values
  static SkillPost createMockSkillPost({
    String? id,
    String? userId,
    String? title,
    String? category,
    int? flatPrice,
    int? perKmPrice,
    double? rating,
    int? reviewCount,
    DateTime? createdAt,
    bool? verified,
  }) {
    final doc = FakeDocumentSnapshot<Map<String, dynamic>>(
      id: id ?? 'test-id',
      data: () => {
        'userId': userId ?? 'test-user',
        'skillTitle': title ?? 'Test Service',
        'category': category ?? 'General',
        'description': 'Test description',
        'flatPrice': flatPrice,
        'perKmPrice': perKmPrice,
        'images': ['https://example.com/image.jpg'],
        'address': 'Test Address',
        'coordinates': GeoPoint(12.9716, 77.5946),
        'serviceRadiusMeters': 5000,
        'rating': rating ?? 0.0,
        'reviewCount': reviewCount ?? 0,
        'viewCount': 0,
        'bookingCount': 0,
        'status': 'active',
        'isAtWork': false,
        'verified': verified ?? false,
        'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
        'profile': {'phone': '1234567890'},
      },
    );

    return SkillPost.fromFirestore(doc);
  }

  /// Creates a list of mock SkillPosts
  static List<SkillPost> createMockSkillPosts(int count) {
    return List.generate(
      count,
      (index) => createMockSkillPost(
        id: 'skill-$index',
        title: 'Service $index',
        category: ['Plumber', 'Electrician', 'Carpenter'][index % 3],
        flatPrice: (index + 1) * 100,
        rating: 4.0 + (index * 0.1),
      ),
    );
  }

  /// Validates that a SkillPost has required fields
  static bool isValidSkillPost(SkillPost skill) {
    return skill.id.isNotEmpty &&
        skill.userId.isNotEmpty &&
        skill.title.isNotEmpty &&
        skill.category.isNotEmpty;
  }
}

/// Fake DocumentSnapshot for testing
class FakeDocumentSnapshot<T extends Object?> implements DocumentSnapshot<T> {
  final String id;
  final T Function() _data;

  FakeDocumentSnapshot({required this.id, required T Function() data})
      : _data = data;

  @override
  T? data() => _data();

  @override
  dynamic get(Object field) {
    final data = _data();
    if (data is Map) {
      return data[field.toString()];
    }
    return null;
  }

  @override
  dynamic operator [](Object field) {
    final data = _data();
    if (data is Map) {
      return data[field.toString()];
    }
    return null;
  }

  @override
  bool get exists => true;

  @override
  DocumentReference<T> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

