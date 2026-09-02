# RideSathi — Firebase Configuration & Onboarding Guide

This document explains the Firebase project configuration, platform integration, local development workflow, and manual Firebase Console setup for the **RideSathi** mobile application.

---

## 1. Firebase Project Identity

| Property | Value | Description |
| :--- | :--- | :--- |
| **Project ID** | `ridesathi-f7ca3` | Unique Firebase Project identifier |
| **Project Number** | `984078491668` | Project / FCM messaging sender ID |
| **Auth Domain** | `ridesathi-f7ca3.firebaseapp.com` | Firebase Auth web redirect domain |
| **Storage Bucket** | `ridesathi-f7ca3.firebasestorage.app` | Cloud Storage bucket for media/documents |

---

## 2. Platform Configuration Matrix

| Platform | Status | Configuration Location | Details |
| :--- | :---: | :--- | :--- |
| **Android** | **Configured** | `android/app/google-services.json` | Package: `com.ridesathi.ridesathi`<br>Google Services Gradle plugin configured in `settings.gradle.kts` and `build.gradle.kts`. |
| **Web** | **Configured** | `lib/firebase_options.dart` | Web App ID: `1:984078491668:web:7d106ce888ec2741c5c701`<br>Measurement ID: `G-ZNDBSNT05Z`. |
| **iOS** | **Pending** | `ios/Runner/GoogleService-Info.plist` | Requires manual registration in Firebase Console when iOS deployment is initiated. |

---

## 3. Initialization Architecture

Firebase Core is initialized once at application startup before any widget rendering or service access:

```text
main() [main.dart]
   ↓
FirebaseService.initialize() [firebase_service.dart]
   ↓
DefaultFirebaseOptions.currentPlatform [firebase_options.dart]
   ↓
RideSathiApp (MaterialApp)
   ↓
SplashScreen (Guarded startup navigation & error recovery)
```

- **Idempotent**: `FirebaseService.initialize()` checks `Firebase.apps.isNotEmpty` to prevent duplicate initialization during hot reloads or test executions.
- **Resilient**: If Firebase initialization encounters an issue (e.g. offline or unconfigured environment), it catches the exception and exposes `FirebaseService.isInitialized == false`, allowing `SplashScreen` to render a user-friendly `ErrorView` with a retry mechanism instead of crashing.

---

## 4. Manual Firebase Console Prerequisites

When provisioning a new Firebase project or verifying the existing environment, complete the following in the [Firebase Console](https://console.firebase.google.com):

### A. Authentication
1. Navigate to **Build $\rightarrow$ Authentication $\rightarrow$ Sign-in method**.
2. Enable the **Email/Password** sign-in provider.
3. Keep *Email link (passwordless sign-in)* disabled unless specified.

### B. Cloud Firestore (For PR 10+)
1. Navigate to **Build $\rightarrow$ Firestore Database**.
2. If not already created, click **Create database**.
3. Select appropriate location (e.g., `asia-south1` for India / regional focus).
4. Start in **Production mode** (Security Rules will be established in subsequent PRs).

### C. Cloud Storage (For PR 10+)
1. Navigate to **Build $\rightarrow$ Storage**.
2. Verify default storage bucket `ridesathi-f7ca3.firebasestorage.app` is provisioned.

### D. iOS App Registration (When iOS is Target)
1. Add an iOS app in the project dashboard with Bundle ID: `com.ridesathi.ridesathi`.
2. Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
3. Run `flutterfire configure` to generate iOS options in `lib/firebase_options.dart`.

---

## 5. Local Developer Setup & FlutterFire CLI

### Initial Setup
```bash
# 1. Install dependencies
flutter pub get

# 2. Run static analysis
flutter analyze

# 3. Execute test suite
flutter test

# 4. Run application
flutter run -d chrome      # Web
flutter run               # Connected Android device / emulator
```

### When to Run `flutterfire configure`
- **Do NOT** run `flutterfire configure` routinely; it will overwrite existing tested configuration.
- **Only** run `flutterfire configure` if:
  1. Adding a new platform (e.g., iOS or macOS).
  2. Migrating to a new Firebase project.

---

## 6. Security & Credential Rules

> [!IMPORTANT]
> **Never Commit Server Secrets or Service Account Keys**:
> - Client configuration files (`google-services.json`, `firebase_options.dart`) contain public platform identifiers and client API keys necessary for mobile app connectivity. These are designed by Google to be embedded in client binaries.
> - **Private service account keys** (JSON files downloaded from Google Cloud IAM / Service Accounts), Admin SDK private keys, and environment passwords must **NEVER** be placed in the repository or committed to Git.

---

## 7. Rider Profile & Firestore Data Contract (PR 12)

### Collection Structure: `users/{uid}`
When a rider registers via `SignupScreen`, their account is created in Firebase Authentication, followed by their user profile document creation in Cloud Firestore under the `users` collection:

```text
users/
  └── {uid}/
        ├── id: string (Firebase Auth UID)
        ├── name: string (Full Name, min 2 chars)
        ├── email: string (Email address)
        ├── phoneNumber: string (Mobile phone number)
        ├── role: string ("rider")
        ├── isUnionVerified: boolean (false by default)
        ├── createdAt: timestamp (server timestamp)
        └── updatedAt: timestamp (server timestamp)
```

### Security & Integrity Rules:
1. **No Password Storage**: Passwords are managed strictly by Firebase Authentication and are never written to Firestore.
2. **Deterministic Document ID**: Document ID in Firestore matches the Firebase Auth `uid` exactly.
3. **Role Enforcement**: Newly registered users are assigned `UserRole.rider`. Arbitrary role injection is blocked by service constraints.
4. **Partial-Failure Behavior**: If authentication succeeds but Firestore profile creation fails (e.g. network interruption or permission error), the application reports a clear error state. The auth account is preserved so profile creation can be retried on next session.

