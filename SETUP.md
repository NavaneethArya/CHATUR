# Setup Guide - Chatur Frontend

This guide will help you set up the Chatur Flutter application on your local machine.

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.7.2 or higher)
  - Download from [flutter.dev](https://flutter.dev/docs/get-started/install)
  - Verify installation: `flutter doctor`

- **Dart SDK** (3.7.2 or higher)
  - Included with Flutter

- **Android Studio** or **VS Code**
  - Android Studio: [Download](https://developer.android.com/studio)
  - VS Code: [Download](https://code.visualstudio.com/)

- **Git**
  - Download from [git-scm.com](https://git-scm.com/downloads)

- **Firebase Account**
  - Sign up at [Firebase Console](https://console.firebase.google.com/)

- **Google Cloud Account**
  - Required for Gemini AI API
  - Sign up at [Google Cloud](https://cloud.google.com/)

## Step-by-Step Setup

### 1. Clone the Repository

```bash
git clone https://github.com/NavaneethArya/CHATUR.git
cd CHATUR
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

#### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: "Chatur"
4. Follow the setup wizard

#### 3.2 Android Configuration

1. In Firebase Console, click "Add app" → Android
2. Register app with package name: `com.example.chatur_frontend`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### 3.3 iOS Configuration (if developing for iOS)

1. In Firebase Console, click "Add app" → iOS
2. Register app with bundle ID
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory

#### 3.4 Enable Firebase Services

Enable the following in Firebase Console:

- **Authentication**
  - Phone Authentication
  - Email/Password
  - Google Sign-In

- **Firestore Database**
  - Create database in production mode
  - Set up security rules (see below)

- **Firebase Storage**
  - Create storage bucket
  - Set up security rules

- **Firebase Analytics** (optional)

#### 3.5 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Skills subcollection
      match /skills/{skillId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == resource.data.userId;
      }
      
      // Cart subcollection
      match /cart/{cartId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Stores collection
    match /stores/{storeId} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == storeId;
      
      // Products subcollection
      match /products/{productId} {
        allow read: if true;
        allow write: if request.auth != null && request.auth.uid == storeId;
      }
    }
    
    // Events collection
    match /events/{eventId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

#### 3.6 Storage Security Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /stores/{storeId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null && request.auth.uid == storeId;
    }
    
    match /skills/{skillId}/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 4. API Keys Configuration

#### 4.1 Gemini AI API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add the key to your environment or configuration file

**Note**: Never commit API keys to version control!

#### 4.2 Cloudinary Configuration (if used)

1. Sign up at [Cloudinary](https://cloudinary.com/)
2. Get your Cloud Name and Upload Preset
3. Update in the code where Cloudinary is used

### 5. Android Setup

#### 5.1 Update Android Configuration

Edit `android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.example.chatur_frontend"
    compileSdk = 36
    
    defaultConfig {
        applicationId = "com.example.chatur_frontend"
        minSdk = 23
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0"
    }
}
```

#### 5.2 Update AndroidManifest.xml

Ensure permissions are set in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### 6. iOS Setup (if developing for iOS)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Update bundle identifier
3. Configure signing & capabilities
4. Add required permissions in `Info.plist`

### 7. Run the Application

#### Debug Mode

```bash
flutter run
```

#### Release Mode (Android)

```bash
flutter run --release
```

#### Build APK

```bash
flutter build apk --release
```

#### Build App Bundle

```bash
flutter build appbundle --release
```

## Troubleshooting

### Common Issues

#### 1. Flutter Doctor Issues

Run `flutter doctor` and fix any issues:
- Accept Android licenses: `flutter doctor --android-licenses`
- Install missing dependencies

#### 2. Firebase Not Initialized

- Ensure `google-services.json` is in correct location
- Check Firebase initialization in `main.dart`
- Verify Firebase project configuration

#### 3. Build Errors

- Clean build: `flutter clean`
- Get dependencies: `flutter pub get`
- Rebuild: `flutter build apk`

#### 4. API Key Errors

- Verify API keys are correctly set
- Check API quotas and limits
- Ensure keys are not exposed in code

#### 5. Permission Errors

- Check AndroidManifest.xml permissions
- Verify runtime permission requests
- Test on physical device if needed

### Getting Help

- Check [Flutter Documentation](https://flutter.dev/docs)
- Review [Firebase Documentation](https://firebase.google.com/docs)
- Open an issue in the repository
- Check existing issues and discussions

## Environment Variables

Create a `.env` file (not committed to git):

```env
GEMINI_API_KEY=your_api_key_here
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_preset
```

## Next Steps

- Read [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines
- Check [README.md](README.md) for project overview
- Review code structure in `lib/` directory

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Dart Language Tour](https://dart.dev/guides/language/language-tour)
- [Material Design](https://material.io/design)

---

Happy Coding! 🚀

