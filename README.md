# HADIR — Daily Check-in & Emotional Support

> A daily check-in app featuring **Hadi**, a friendly mascot designed to encourage emotional awareness, daily connection, and care for oneself and others.

<p align="center">
  <img src="docs/screenshots/icon.png" alt="HADIR app icon" width="140">
</p>

## Table of Contents

1. [Background](#background)
2. [Description](#description)
3. [Key Features](#key-features)
4. [Technology Stack](#technology-stack)
5. [Prerequisites](#prerequisites)
6. [Installation](#installation)
7. [Running the App](#running-the-app)
8. [Building the APK](#building-the-apk)
9. [Project Structure](#project-structure)
10. [Language](#language)
11. [Privacy and Safety](#privacy-and-safety)
12. [Prototype Status and Limitations](#prototype-status-and-limitations)
13. [Meet Hadi](#meet-hadi)
14. [Meaning Behind HADIR](#meaning-behind-hadir)
15. [Team](#team)

## Background

Suicide remains a serious global public health concern. According to the World Health Organization (WHO), more than 720,000 people die by suicide every year worldwide.

Behind this issue are complex and interconnected factors, including emotional distress, loneliness, difficult life circumstances, and barriers to seeking support. Some people find it difficult to express what they feel or ask for help when they need it. Stigma surrounding mental health can make these challenges even harder to discuss.

HADIR was created in response to this concern. The project explores how simple digital tools can encourage people to check in with themselves, recognize their emotional well-being, and stay connected with people who care about them.

HADIR is built around a simple idea: **being present matters**. A small daily check-in cannot solve every problem, but it can be a starting point for reflection, connection, and reaching out for support.

*Reference: [World Health Organization — Suicide](https://www.who.int/news-room/fact-sheets/detail/suicide).*

## Description

HADIR is a mobile application prototype focused on daily check-ins, emotional self-awareness, and personal connection. It encourages users to build a simple habit of acknowledging how they are doing while providing features such as mood tracking, a private diary, an emotional well-being check, and emergency contact settings.

Users are accompanied by **Hadi**, a friendly mascot whose expressions, poses, and encouraging messages make the experience feel more approachable and less judgmental.

HADIR also explores a system in which designated emergency contacts could be notified after a user misses check-ins for a configured period. However, automatic alert emails are not yet implemented in this prototype.

## Key Features

| Feature | Description |
|---|---|
| **Daily Check-in** | A main check-in button featuring Hadi. After checking in, Hadi raises his hands and waves while saying, "I'm here!" |
| **Emergency Contacts** | Add up to five contacts, specify each relationship, configure the number of days without a check-in before an alert, and set an alert email time. Automatic alert emails are not active yet. |
| **Check-in Pause** | Schedule a break from check-ins for up to 14 days without reminders or alerts, according to the app's configured behavior. |
| **Streaks and Reports** | View daily streaks, personal bests, an 84-day heart-shaped history, weekly summaries, and mood statistics. |
| **Mood Tracking** | Record a daily mood as Good, Okay, or Not Good. |
| **Private Diary** | Write personal notes stored on the device. After selecting a mood, users can write a diary entry or skip it. |
| **Emotional Well-being Check** | Includes 100 questions across 10 sections covering activities, physical well-being, anxiety, fear of loss, loneliness, mood, social relationships, thoughts about death, plans and safety, and protective factors. Results are grouped into five levels, with help contacts displayed when needed. This screening is not clinically validated and does not provide a diagnosis. |
| **Hope Box** | Save photos of happy memories with notes and optional links. Photos can appear behind the check-in button in different shapes, with adjustable opacity. |
| **Hadi and Anonymous Letters** | Tap Hadi to see different poses and encouraging messages. After several taps, Hadi temporarily leaves and returns with a letter. The current letter experience uses a predefined list; user-to-user letter delivery is not yet connected to a backend. |
| **Two Languages** | Supports Indonesian and English, with automatic device-language detection or manual selection. |
| **Adjustable Text Size** | Choose small, medium, or large text for accessibility. |

## Technology Stack

- **Flutter** and **Dart**, using Material 3
- Local storage: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- Photo picker: [`image_picker`](https://pub.dev/packages/image_picker)
- Opening links: [`url_launcher`](https://pub.dev/packages/url_launcher)
- Localization: `flutter_localizations`
- App icons: [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
- Custom mascot drawing and animation using Flutter's `CustomPainter`

Hadi is drawn directly in code, allowing the mascot's poses and expressions to be customized and animated without requiring separate image files for each pose.

## Prerequisites

- The Flutter SDK version compatible with the project's `pubspec.yaml`
- [Git](https://git-scm.com/downloads)
- One of the following:
  - **Android Studio** with the Android SDK, for an emulator or Android device
  - **Google Chrome**, to run the web version
- An editor such as Visual Studio Code or Android Studio with the Flutter and Dart plugins

Check your development environment:

```bash
flutter doctor
```

Resolve any required toolchain issues before running the app.

## Installation

Clone the repository:

```bash
git clone https://github.com/taqiyyamafaza22-create/hadir-app.git
cd hadir-app
```

Install the dependencies:

```bash
flutter pub get
```

For iOS devices, verify that the photo library permission is configured in `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>HADIR needs access to your photos to add memories to your Hope Box.</string>
```

## Running the App

### On an Android device

1. Enable **Developer Options** and **USB debugging** on your phone.
2. Connect your phone to your computer.
3. Check whether Flutter detects the device:

   ```bash
   flutter devices
   ```

4. Run the application:

   ```bash
   flutter run
   ```

### On an Android emulator

Open **Android Studio → Device Manager**, start an emulator, and run:

```bash
flutter run
```

### In Google Chrome

Run the web version using:

```bash
flutter run -d chrome
```

> **Note:** After adding a new package, stop the app and restart it with `flutter run`. A hot reload alone may not initialize a newly added plugin.

### Signing In

Login is currently simulated for demonstration purposes. Select **Sign in with Email** or **Sign in with Google**, then enter an email address to continue. Follow the onboarding steps, choose your text size and language, enter your name, and add at least one emergency contact.

The simulated login does not authenticate a real Google account or verify an email address.

## Building the APK

Build a release APK:

```bash
flutter build apk --release
```

The output file will be located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

To create smaller APK files for different processor architectures, run:

```bash
flutter build apk --split-per-abi
```

If you change the app icon, regenerate it with:

```bash
dart run flutter_launcher_icons
```

## Project Structure

```text
lib/
├── main.dart               # Main app, state, and primary screens
├── app_theme.dart          # Colors and shared styling
├── i18n.dart               # Localization helpers
├── i18n_strings.dart       # English and Indonesian translations
├── mascot.dart             # Hadi mascot, poses, and animations
├── hadi_companion.dart     # Hadi interactions and letters
├── letters.dart            # Anonymous letters and archive
├── diary.dart              # Private diary
├── hope_box.dart           # Hope Box and saved photos
├── feature_menu.dart       # Feature navigation cards
├── splash_screen.dart      # Splash screen
├── screening_screens.dart  # Emotional Well-being Check screens
├── models/
│   └── models.dart         # Question and answer models
├── data/
│   └── question_bank.dart  # Screening question bank
└── services/
    └── scoring.dart        # Score calculation and risk levels

assets/
└── icon/                   # App icon assets

docs/
└── screenshots/            # README images and screenshots
```

## Language

HADIR supports **Indonesian and English**.

- **Automatic:** follows the device language when supported.
- **Manual:** users can select their preferred language during onboarding or in Settings.

Translations are managed in `lib/i18n_strings.dart`.

## Privacy and Safety

- Check-ins, moods, diary entries, Hope Box photos, and emergency contact details are stored locally on the user's device in the current prototype.
- Answers to the Emotional Well-being Check are not saved and are not sent to emergency contacts.
- Anonymous letters currently use a predefined list of encouraging messages rather than unrestricted user-submitted text.
- Help contacts are displayed for certain screening results, and a help panel appears when a user gives a positive response to a safety-related question.
- **HADIR is not an emergency service, a diagnostic tool, or a substitute for professional mental health care.**
- The screening questions and scoring thresholds have not been clinically validated. They must be reviewed by a qualified mental health professional before the screening is used to guide real-world decisions.

Emergency contact information and service numbers should be verified for the user's location before public release. Users experiencing an immediate emergency should contact local emergency services or seek help from a nearby hospital.

## Prototype Status and Limitations

HADIR is a **prototype for demonstration purposes**. Some features are implemented locally, while others require further development.

| Feature | Current Status |
|---|---|
| **Email and Google login** | Simulated locally; no real authentication |
| **Emergency alert emails** | Not implemented; requires a backend and an email service |
| **Check-in reminders** | Settings are saved, but system notifications are not active yet |
| **Anonymous letters** | Uses predefined messages; user-to-user delivery is not connected to a backend |
| **Hope Box photos** | Stored locally, with a maximum of 30 photos |
| **Emotional Well-being Check** | Prototype screening; questions and scoring are not clinically validated |

### Planned Improvements

- Real authentication using Firebase Authentication
- A backend and email service for emergency contact notifications
- Scheduled local notifications
- User-to-user anonymous letters, including reporting and blocking features
- Review and clinical validation of the screening questions and scoring thresholds
- Further usability, privacy, and safety testing

## Meet Hadi

**Hadi** is HADIR's friendly mascot and daily companion. Through expressive poses, waves, heart gestures, and encouraging messages, Hadi helps make the check-in experience feel welcoming rather than clinical or judgmental.

Hadi represents warmth, care, and the reminder that people deserve to be heard and supported.

## Meaning Behind HADIR

The name **HADIR** comes from the Indonesian word *hadir*, meaning **"to be present."**

For this project, being present means acknowledging your own feelings, taking a moment to check in with yourself, and staying connected with people who care about you.

HADIR's message is simple: **be present for yourself, and for one another.**

## Team

| Name | Role |
|---|---|
| Taqiyya Mafaza | Team Leader, Developer / Designer |
| Natali Rahel Rowina Sitepu | Designer |

---

Created for a competition.

The Hadi mascot and original project content are the work of the team that created them.
