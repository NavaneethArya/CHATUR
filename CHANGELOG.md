# Changelog

All notable changes to the Chatur project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Payment gateway integration
- Push notifications
- Offline mode support
- Advanced analytics dashboard

## [0.1.0] - 2024-12-XX

### Added
- Initial release of Chatur platform
- **Authentication Module**
  - Phone OTP authentication
  - Email/password authentication
  - Google Sign-In integration
  - Separate registration for Citizens and Government Employees

- **Home Dashboard**
  - Personalized feed with recommended schemes
  - Quick access to all modules
  - AI chatbot integration
  - Document assistant access

- **Government Schemes Module**
  - State government schemes database
  - Central government schemes by ministry
  - AI-powered eligibility checker
  - Multilingual support (English, Kannada, Hindi)
  - Application guidance and step-by-step process

- **Skills Marketplace**
  - 11 service categories (Carpenter, Electrician, Plumber, Cook, Painter, Driver, Mechanic, Tutor, Gardener, Cleaner, Tailor)
  - Service provider profiles with ratings
  - Location-based search
  - QR code integration for ratings
  - Direct contact and booking

- **Events Module**
  - Event discovery and browsing
  - Event categories and filtering
  - Bookmarking functionality
  - Event notifications
  - Panchayat integration

- **Local Store**
  - Store listings and browsing
  - Product catalog with images
  - Shopping cart functionality
  - Store profiles with contact details
  - Multiple product categories

- **AI Document Assistant**
  - OCR text extraction from forms
  - AI form field detection using Gemini AI
  - Multilingual support
  - Smart question generation
  - Filled form download

- **AI Chatbot**
  - Gemini AI integration
  - Multilingual chat support
  - Voice input/output
  - Chat history persistence
  - Scheme information queries

- **User Profile**
  - Profile management
  - Service provider profiles
  - Review and rating system
  - Saved items and bookmarks

### Technical
- Flutter 3.29.3
- Dart 3.7.2
- Firebase integration (Auth, Firestore, Storage, Analytics)
- Google Gemini AI integration
- Google ML Kit for text recognition
- OpenStreetMap integration
- Cloudinary for image storage
- Comprehensive error handling
- Code optimization and performance improvements

### Fixed
- Resolved unused import warnings
- Fixed exception handling with proper rethrow
- Removed unnecessary null assertions
- Optimized build configuration

### Security
- Secure authentication flows
- Firebase security rules implementation
- API key management
- Data encryption in transit

---

## Version History

- **0.1.0** - Initial release with core features

---

## Notes

- All dates are in YYYY-MM-DD format
- Breaking changes are marked with ⚠️
- Security updates are marked with 🔒

