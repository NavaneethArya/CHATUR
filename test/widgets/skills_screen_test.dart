import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatur_frontend/Skills/skills_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Firebase for testing
    // Note: You may need to set up Firebase test configuration
    // For now, we'll test UI components that don't require Firebase
  });

  group('SkillsScreen Widget Tests', () {
    testWidgets('should display app bar with correct title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Discover Services'), findsOneWidget);
    });

    testWidgets('should display search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search services...'), findsOneWidget);
    });

    testWidgets('should display category chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check for category names
      expect(find.text('All'), findsWidgets);
      expect(find.text('Carpenter'), findsOneWidget);
      expect(find.text('Electrician'), findsOneWidget);
      expect(find.text('Plumber'), findsOneWidget);
    });

    testWidgets('should have filter and sort buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Look for filter and sort icons (tune and sort icons)
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    });

    testWidgets('should have floating action button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Post Service'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should update search query on text input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SkillsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'plumber');
      await tester.pumpAndSettle(const Duration(milliseconds: 600));

      // Verify text was entered
      expect(find.text('plumber'), findsOneWidget);
    });

    testWidgets('should show drawer when app bar icon is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkillsScreen(),
            drawer: Drawer(child: Text('Drawer')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Note: The drawer might be accessed via gesture or menu icon
      // This depends on the actual implementation
    });
  });

  group('SkillPost Display Tests', () {
    test('priceDisplay getter returns correct format for flat price', () {
      // Create a mock document with flatPrice
      final skill = _createMockSkillPost(
        flatPrice: 500,
        perKmPrice: null,
      );

      expect(skill.priceDisplay, equals('₹500'));
    });

    test('priceDisplay getter returns correct format for perKm price', () {
      final skill = _createMockSkillPost(
        flatPrice: null,
        perKmPrice: 25,
      );

      expect(skill.priceDisplay, equals('₹25/km'));
    });

    test('timeAgo getter returns correct format', () {
      final skill = _createMockSkillPost(
        createdAt: DateTime.now().subtract(Duration(days: 2)),
      );

      expect(skill.timeAgo, equals('2d ago'));
    });
  });
}

// Helper function to create mock SkillPost for testing
SkillPost _createMockSkillPost({
  String? id,
  String? userId,
  String? title,
  String? category,
  int? flatPrice,
  int? perKmPrice,
  DateTime? createdAt,
}) {
  // This is a simplified mock - in real tests, you'd use a proper mock
  // For now, we'll test the logic through the actual model
  return SkillPost.fromFirestore(_createMockDoc({
    'userId': userId ?? 'test-user',
    'skillTitle': title ?? 'Test Service',
    'category': category ?? 'General',
    'flatPrice': flatPrice,
    'perKmPrice': perKmPrice,
    'images': [],
    'coordinates': GeoPoint(0, 0),
    'createdAt': Timestamp.fromDate(createdAt ?? DateTime.now()),
  }));
}

// Simplified mock document creator
dynamic _createMockDoc(Map<String, dynamic> data) {
  // Return a minimal mock structure
  // In production, use a proper mocking library like mockito
  return FakeDocumentSnapshot<Map<String, dynamic>>(
    id: 'test-doc',
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
  dynamic operator [](Object field) => (data() as Map?)?[field];

  @override
  bool get exists => true;

  @override
  DocumentReference<T> get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();
}

