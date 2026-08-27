# RideSathi — Baseline Engineering Report

**Date:** August 24, 2026  
**Repository URL:** `https://github.com/kalviumcommunity/S115-0826-Team02-Mobile-App-Development-with-Flutter---Firebase-RideSathi.git`  
**Branch:** `feat/pr-01-project-foundation`  
**Author:** Senior Flutter Engineering Team  

---

## 1. Current Project Status

Upon starting the baseline audit, the remote GitHub repository was verified as a newly created, empty repository (0 commits, 0 branches).

* **Repository State:** Clean slate initialized on default `main` branch and branched to `feat/pr-01-project-foundation`.
* **Flutter SDK:** Flutter 3.47.1 (Channel stable, Dart 3.13.1, DevTools 2.60.0) configured and verified.
* **Target Platforms:** Android, iOS, Web.
* **Application Identifiers:**
  * App Name: `RideSathi`
  * Package ID: `com.ridesathi.ridesathi`

---

## 2. Existing Features & Audit Findings

* **Pre-existing Code:** None (Fresh repository initialization).
* **Pre-existing Functionality:** None.
* **Pre-existing Technical Debt:** None.

---

## 3. Architecture Overview

A clean, modular, layered Flutter architecture has been established under `lib/` to support scalable development across upcoming PRs:

```text
lib/
├── main.dart                   # Application entry point & service initialization
├── core/
│   ├── constants/              # Application-wide constants & branding strings
│   ├── routes/                 # Centralized route definitions & navigation
│   └── theme/                  # Material 3 design system & custom color palette
├── models/
│   ├── user_model.dart         # User data representation (Rider / Driver / Dispatcher)
│   └── ride_model.dart         # Ride request data model structure
├── services/
│   └── firebase_service.dart   # Centralized Firebase initialization & state manager
├── widgets/
│   ├── custom_button.dart      # Reusable primary & secondary action buttons
│   ├── info_card.dart          # Reusable system status & feature summary cards
│   └── union_badge.dart        # Union identity & verification badge widget
└── screens/
    ├── splash_screen.dart      # Brand splash screen with animated transition
    └── home_screen.dart        # RideSathi foundation dashboard shell
```

---

## 4. Dependencies Audit

All project dependencies have been strictly selected and validated. No arbitrary or unneeded packages were added.

| Package | Version | Justification |
| :--- | :--- | :--- |
| `flutter` | SDK | Core Flutter framework |
| `cupertino_icons` | `^1.0.8` | iOS Cupertino style icons |
| `firebase_core` | `^3.12.1` | Firebase core SDK for app initialization |
| `cloud_firestore` | `^5.6.5` | Firestore database client for ride dispatching and real-time state |
| `firebase_auth` | `^5.5.1` | Authentication framework for Union riders, drivers, and dispatchers |
| `google_fonts` | `^6.2.1` | Typography design system (`GoogleFonts.inter`) |

---

## 5. Firebase Integration State

* `firebase_core`, `cloud_firestore`, and `firebase_auth` dependencies have been added to `pubspec.yaml` and resolved cleanly.
* `FirebaseService` wrapper has been introduced to safely manage initialization state with graceful fallbacks for local/offline development prior to native console configuration.
* Native `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are pending environment setup in subsequent PRs.

---

## 6. Baseline Validation Results

| Check | Command | Status | Result |
| :--- | :--- | :--- | :--- |
| **Dependency Resolution** | `flutter pub get` | **PASSED** | 39 packages resolved cleanly with 0 errors |
| **Static Code Analysis** | `flutter analyze` | **PASSED** | 0 warnings, 0 errors |
| **Automated Unit & Widget Tests** | `flutter test` | **PASSED** | All widget tests passing |

---

## 7. Known Issues & Next Steps

* **Native Firebase Credentials:** Firebase backend configuration files (`google-services.json` / `firebase_options.dart`) will be integrated when Firebase project keys are provisioned.
* **Authentication & Dispatch:** User authentication flows (PR 02) and Ride Dispatch system (PR 03+) will build upon this clean baseline.
