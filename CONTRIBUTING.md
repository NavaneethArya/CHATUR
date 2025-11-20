# Contributing to Chatur

First off, thank you for considering contributing to Chatur! It's people like you that make Chatur such a great platform.

## Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples to demonstrate the steps**
- **Describe the behavior you observed after following the steps**
- **Explain which behavior you expected to see instead and why**
- **Include screenshots if applicable**
- **Specify the Flutter/Dart version and device information**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use a clear and descriptive title**
- **Provide a step-by-step description of the suggested enhancement**
- **Provide specific examples to demonstrate the steps**
- **Describe the current behavior and explain which behavior you expected to see instead**
- **Explain why this enhancement would be useful**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code that should be tested, add tests
3. Ensure the test suite passes
4. Make sure your code follows the style guidelines
5. Write a clear commit message
6. Issue that pull request!

## Development Process

### Setting Up Development Environment

1. **Clone your fork**
   ```bash
   git clone https://github.com/NavaneethArya/CHATUR.git
   cd CHATUR
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/originalowner/chatur_frontend.git
   ```

3. **Install dependencies**
   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Coding Standards

#### Dart/Flutter Style Guide

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `flutter analyze` to check for issues
- Format code using `dart format`
- Maximum line length: 100 characters

#### Code Structure

- **File Naming**: Use snake_case for file names (e.g., `my_cart.dart`)
- **Class Naming**: Use PascalCase for class names (e.g., `MyCartPage`)
- **Variable Naming**: Use camelCase for variables (e.g., `cartItems`)
- **Constants**: Use lowerCamelCase for constants (e.g., `maxItems`)

#### Widget Organization

```dart
// 1. Imports
import 'package:flutter/material.dart';

// 2. Class definition
class MyWidget extends StatefulWidget {
  // 3. Constructor
  const MyWidget({super.key});
  
  // 4. State class
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  // 5. Variables
  // 6. Lifecycle methods
  // 7. Methods
  // 8. Build method
}
```

#### Comments

- Write clear, concise comments
- Use `///` for documentation comments
- Explain **why**, not **what**
- Keep comments up-to-date with code changes

#### Example

```dart
/// Calculates the total price of items in the cart.
/// 
/// Returns the sum of all item prices, or 0.0 if cart is empty.
double calculateTotal() {
  if (cartItems.isEmpty) return 0.0;
  return cartItems.fold(0.0, (sum, item) => sum + item.price);
}
```

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **chore**: Changes to build process or auxiliary tools

**Format**: `<type>(<scope>): <subject>`

**Examples**:
```
feat(cart): Add remove item functionality
fix(auth): Resolve OTP verification issue
docs(readme): Update installation instructions
refactor(store): Optimize product loading
```

### Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Ensure all tests pass before submitting PR
- Aim for at least 70% code coverage

### Pull Request Process

1. **Update your fork**
   ```bash
   git checkout main
   git pull upstream main
   git push origin main
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clean, tested code
   - Follow coding standards
   - Update documentation if needed

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(module): Description of changes"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Use a clear title and description
   - Reference related issues
   - Add screenshots if UI changes
   - Request review from maintainers

### PR Review Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] No new warnings introduced
- [ ] Screenshots added (for UI changes)

## Project-Specific Guidelines

### Firebase

- Never commit sensitive keys or credentials
- Use environment variables for API keys
- Follow Firebase security rules best practices

### State Management

- Use Provider or GetX consistently
- Avoid global state when local state suffices
- Keep state as close to where it's used as possible

### UI/UX

- Follow Material Design guidelines
- Ensure responsive design for different screen sizes
- Test on multiple devices
- Maintain consistent color scheme and typography

### Performance

- Optimize images before adding to assets
- Use `cached_network_image` for network images
- Implement pagination for large lists
- Avoid unnecessary rebuilds

## Getting Help

- Check existing issues and discussions
- Ask questions in discussions
- Reach out to maintainers

## Recognition

Contributors will be recognized in:
- README.md contributors section
- Release notes
- Project documentation

Thank you for contributing to Chatur! 🎉

