# HADIR

> A daily check-in app featuring **Hadi**, a friendly mascot that helps people stay connected with their loved ones and take care of their emotional well-being.

<p align="center">
  <img src="docs/screenshots/icon.png" alt="HADIR app icon" width="140">
</p>

## Table of Contents

1. [Description](#description)
2. [Key Features](#key-features)
3. [Technology Stack](#technology-stack)
4. [Prerequisites](#prerequisites)
5. [Installation](#installation)
6. [Running the App](#running-the-app)
7. [Building the APK](#building-the-apk)
8. [Project Structure](#project-structure)
9. [Language](#language)
10. [Privacy and Safety](#privacy-and-safety)
11. [Prototype Status and Limitations](#prototype-status-and-limitations)
12. [Team](#team)

## Description

Many people feel anxious, afraid of losing someone, or lonely, but find it difficult to ask for help. HADIR encourages users to complete a simple **daily check-in**. If a user stops checking in for several days, the system is designed to notify the **emergency contacts** selected by that user.

Users are accompanied by **Hadi**, a mascot who waves, thinks, hugs a heart, and carries letters. Hadi makes the daily check-in habit feel warm and non-judgmental.

The name **HADIR** comes from the Indonesian word *hadir*, meaning “to be present”—for yourself and for others.

## Key Features

| Feature | Description |
|---|---|
| **Daily check-in** | A large button featuring Hadi. Before checking in, Hadi's hands are down. After checking in, Hadi raises his hands and waves while saying, “I'm here!” |
| **Emergency contacts** | Add up to 5 contacts, set each contact's relationship, configure the number of days without a check-in before an alert, and set the alert email time. |
| **Check-in pause** | Schedule a break from check-ins for up to 14 days without reminders or alerts. |
| **Streaks and reports** | Track daily streaks, personal bests, an 84-day heart-shaped history, weekly summaries, and mood statistics. |
| **Mood tracking** | Record your daily mood as Good, Okay, or Not Good. |
| **Diary** | Write private notes stored on your device. After selecting a mood, the app offers the option to write a diary entry, which can be skipped. |
| **Emotional Well-being Check** | Includes 100 questions across 10 sections: activities, physical well-being, anxiety, fear of loss, loneliness, mood, social relationships, thoughts about death, plans and safety, and protective factors. Results are grouped into five levels, with crisis contacts displayed when needed. |
| **Hope Box** | Save photos of happy memories with notes and optional links. Photos can float behind the check-in button in different shapes (heart, circle, diamond, square, or star), with adjustable opacity. |
| **Hadi and Anonymous Letters** | Tap Hadi to see random poses and encouraging messages. After several taps, Hadi leaves for 10 seconds and returns with a letter from a “stranger.” Users can also send anonymous encouraging letters. |
| **Two languages** | Supports Indonesian and English, with automatic device-language detection or manual selection. |
| **Text size** | Choose small, medium, or large text for accessibility. |

## Technology Stack

- **Flutter** and **Dart** (Material 3)
- Local storage: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- Photo picker: [`image_picker`](https://pub.dev/packages/image_picker)
- Opening links: [`url_launcher`](https://pub.dev/packages/url_launcher)
- Built-in widget localization: `flutter_localizations`
- App icons: [`flutter_launcher_icons`](https://pub.dev/packages/flutter_launcher_icons)
- Hadi is drawn directly in code using `CustomPainter`, so no image files are required and the mascot's poses can be smoothly animated.

## Prerequisites

- The latest stable [Flutter SDK](https://docs.flutter.dev/get-started/install) (the Dart SDK version must match `^3.13.5` in `pubspec.yaml`)
- [Git](https://git-scm.com/downloads)
- One of the following:
  - **Android Studio** with the Android SDK, for an emulator or Android device, or
  - **Google Chrome**, to run the web version
- An editor such as Visual Studio Code or Android Studio with the Flutter and Dart plugins

Check your development environment:

```bash
flutter doctor
```

All required components should show a check mark.

## Installation

```bash
# 1. Clone the project
git clone https://github.com/<your-username>/<your-repository>.git
cd <your-repository>

# 2. Install dependencies
flutter pub get
```

For iOS devices, add the photo library permission to `ios/Runner/Info.plist` (this is already included if you use the default file):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>HADIR needs access to your photos to add memories to your Hope Box.</string>
```

## Running the App

### On an Android device

1. Enable **Developer Options** and **USB debugging** on your phone, then connect it to your computer.
2. Make sure the device is detected:

   ```bash
   flutter devices
   ```

3. Run the app:

   ```bash
   flutter run
   ```

### On an Android emulator

Open **Android Studio → Device Manager**, start an emulator, and run `flutter run`.

### In Chrome (web)

```bash
flutter run -d chrome
```

> **Note:** After adding a new package with `flutter pub add ...`, stop the app and perform a full restart using `flutter run`. Hot reload alone is not sufficient for a newly added plugin.

### Signing in

Login is currently simulated for demonstration purposes. Select **Sign in with Email** or **Sign in with Google**, then enter any email address (for example, `demo@email.com`). Continue through onboarding: choose your text size and language, enter your name, and add at least one emergency contact.

## Building the APK

```bash
flutter build apk --release
```

The output file will be located at `build/app/outputs/flutter-apk/app-release.apk`. To create smaller APK files for different processor architectures, run:

```bash
flutter build apk --split-per-abi
```

Install `app-arm64-v8a-release.apk` on most modern Android phones. If prompted, allow installation from this source.

If you change the app icon, regenerate it with:

```bash
dart run flutter_launcher_icons
```

## Project Structure

```text
lib/
├── main.dart               # Entry point, app state, Welcome/Onboarding/Home/Report/Settings screens
├── app_theme.dart          # Colors, buttons, styled headings, date helpers
├── i18n.dart               # Two-language system (Text, tr, t2)
├── i18n_strings.dart       # English <-> Indonesian translation dictionary
├── mascot.dart             # Hadi mascot (CustomPainter, poses, and animations)
├── hadi_companion.dart     # Hadi on the Home screen: random poses, letters, countdown
├── letters.dart            # Anonymous letters, archive, and letter screen
├── diary.dart              # Private diary
├── hope_box.dart           # Hope Box and floating photos
├── feature_menu.dart       # Two swipeable feature cards
├── splash_screen.dart      # Splash screen
├── screening_screens.dart  # Emotional Well-being Check screens
├── models/models.dart      # Question, section, and answer-option models
├── data/question_bank.dart # 100 questions
└── services/scoring.dart   # Score calculation, risk levels, and crisis contacts
assets/icon/                # App icon source files
docs/screenshots/           # Screenshots for the README
```

## Language

The app supports **Indonesian and English**.

- **Automatic (default):** follows the device language.
- **Manual:** choose a language in **Settings → Language** or during onboarding.

All translations are managed in `lib/i18n_strings.dart`. To add a new text entry, add an English–Indonesian pair to that file.

## Privacy and Safety

- Check-ins, moods, diary entries, Hope Box photos, and contacts are stored **only on the user's device**.
- **Answers to the Emotional Well-being Check are not saved** and are not sent to emergency contacts.
- Anonymous letters are selected by the system from a predefined list of encouraging messages rather than written as free text, helping prevent harassment.
- At high risk levels, help contacts are displayed at the top of the results. A help panel also appears immediately when a user gives a positive response to a safety-related question.
- **HADIR is not an emergency service, a diagnostic tool, or a substitute for a psychologist or psychiatrist.** In an emergency, call **112** or visit the nearest emergency department. Indonesia's Ministry of Health mental health service is listed as **119 ext. 8**. These numbers must be verified again before public release.
- The 100 questions are based on general domains covered by instruments such as PHQ-9, GAD-7, C-SSRS, and loneliness scales, but **have not been clinically validated**. Before the app is used by real users, the questions and scoring thresholds should be reviewed by a licensed clinical psychologist.

## Prototype Status and Limitations

This app is a **prototype for demonstration purposes**. The following features are still simulated or are not yet connected to a server:

| Feature | Status |
|---|---|
| Google and email login | Simulated locally; accepts any email address |
| Alert emails to emergency contacts | Not sent yet; requires a backend and an email service |
| Check-in reminders | Settings are saved, but system notifications are not active yet |
| Anonymous letters to other users | Sending is simulated; received letters are selected from a built-in list |
| Hope Box photos | Stored locally as small data files, with a maximum of 30 photos |

Planned improvements include authentication with Firebase Auth, a backend for alert emails and user-to-user letters (with reporting and blocking features), scheduled local notifications, and clinical validation of the screening questions.

## Team

| Name | Role |
|---|---|
| Taqiyya Mafaza | Team Leader, Developer / Designer |
| Natali Rahel Rowina Sitepu | Designer |

---

Created for a competition. The copyright for the **Hadi** mascot and all content in this repository belongs to the team that created them.

![Home][def]
[def]: docs/screenshots/home.png