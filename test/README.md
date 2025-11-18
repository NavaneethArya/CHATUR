# Test Suite Documentation

This directory contains comprehensive tests for the Chatur Frontend application.

## Test Structure

```
test/
├── models/              # Unit tests for data models
│   └── skill_post_test.dart
├── widgets/             # Widget tests for UI components
│   ├── skills_screen_test.dart
│   ├── main_screen_test.dart
│   └── home_screen_test.dart
├── integration/         # Integration tests
│   └── app_flow_test.dart
├── unit/                # Unit tests for business logic
│   └── filter_logic_test.dart
└── utils/               # Test utilities and helpers
    └── test_helpers.dart
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/models/skill_post_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Run tests in watch mode
```bash
flutter test --watch
```

## Test Categories

### 1. Unit Tests (`test/models/`, `test/unit/`)
- Test individual models and business logic
- Test filter and sort logic
- Test data transformations

### 2. Widget Tests (`test/widgets/`)
- Test UI components
- Test user interactions
- Test widget rendering

### 3. Integration Tests (`test/integration/`)
- Test complete user flows
- Test navigation
- Test app initialization

## Test Coverage Goals

- **Models**: 100% coverage
- **Business Logic**: 90%+ coverage
- **Widgets**: 80%+ coverage
- **Integration**: Critical flows covered

## Mocking

For Firebase-dependent tests, use:
- `FakeDocumentSnapshot` for Firestore documents
- Firebase test configuration for auth
- Mock services for external APIs

## Best Practices

1. **Isolation**: Each test should be independent
2. **Naming**: Use descriptive test names
3. **Arrange-Act-Assert**: Follow AAA pattern
4. **Setup/Teardown**: Use setUp and tearDown for common logic
5. **Assertions**: Use specific assertions

## Adding New Tests

When adding new features:

1. Create corresponding unit tests for business logic
2. Create widget tests for UI components
3. Add integration tests for new user flows
4. Update this README if needed

## CI/CD Integration

Tests are automatically run on:
- Pull requests
- Commits to main branch
- Before deployments

## Troubleshooting

### Firebase Initialization Errors
- Ensure Firebase test configuration is set up
- Use Firebase emulators for testing

### Widget Test Failures
- Check for async operations (use `pumpAndSettle`)
- Verify mock data setup
- Check widget tree structure

### Flaky Tests
- Review async operations
- Check for race conditions
- Verify test isolation

