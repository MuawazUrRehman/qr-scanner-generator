# QR Scanner & Generator

![Flutter](https://img.shields.io/badge/Flutter-^3.10.7-blue.svg)
![Dart](https://img.shields.io/badge/Dart-^3.0.0-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

A comprehensive, robust, and feature-rich **QR Code Scanner and Generator** application built with Flutter. This project leverages Native device capabilities for high-performance scanning, local NoSQL data storage for histories and favorites, and dynamic theme handling for a modern user experience.

---

## 🚀 Features

- **Blazing Fast Scanning**: Powered by `mobile_scanner` for rapid and accurate detection of QR codes and Barcodes.
- **Dynamic QR Creation**: Generate custom QR codes for URLs, text, contact cards (vCard), Wi-Fi, and more using `qr_flutter`.
- **Scan History & Favorites**: Fully persistent local storage using `hive` and `hive_flutter` to track previous scans and save critical ones to your favorites.
- **Batch Scanning**: Rapidly scan multiple codes in sequence without leaving the camera interface.
- **Rich Action Integrations**:
  - Open scanned URLs in the browser.
  - Automatically add scanned contacts to your device via `flutter_contacts`.
  - Share scan results natively using `share_plus`.
  - Save generated QR codes directly to the device gallery using `gal`.
- **Dynamic Theming**: Seamless toggling between Light and Dark mode using Provider-based state management.
- **Haptic & Audio Feedback**: Confirmed scans optionally play a beep sound (`audioplayers`) and trigger device vibrations.

---

## 🏗️ Architecture

This project is built using a **Feature-First Architecture**. Instead of grouping files by type (e.g., all UI files together, all models together), the project is modularized by feature, making it highly scalable and easy to maintain.

```
lib/
├── app/                  # App-level routing and initialization
├── common/               # Reusable widgets and UI components
├── core/                 # Core services (e.g., HiveDatabase, API clients)
├── features/             # Individual feature modules
│   ├── batch/            # Batch scanning logic and UI
│   ├── create/           # QR code creation screens
│   ├── favorites/        # Saved/Favorite QR codes viewer
│   ├── history/          # Scan history implementations
│   ├── home/             # Main dashboard and navigation
│   ├── result/           # Scan result parsing and actions
│   ├── settings/         # App preferences and dark/light mode provider
│   └── splash/           # Launch screen
└── main.dart             # Application entry point
```

**State Management** is handled via `Provider`. The `SettingsProvider` injected at the root of the app handles global configurations like `ThemeMode`.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter SDK](https://flutter.dev/) (>= 3.10.7)
- **Local Database**: [Hive](https://pub.dev/packages/hive) & [Hive Flutter](https://pub.dev/packages/hive_flutter)
- **Scanning**: [Mobile Scanner](https://pub.dev/packages/mobile_scanner)
- **QR Generation**: [QR Flutter](https://pub.dev/packages/qr_flutter)
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Permissions**: [Permission Handler](https://pub.dev/packages/permission_handler)
- **Localization**: [Easy Localization](https://pub.dev/packages/easy_localization)
- **Other Utilities**: `url_launcher`, `share_plus`, `gal`, `flutter_contacts`, `audioplayers`, `image_picker`

---

## 💻 Getting Started for Contributors

We welcome contributions to the QR Scanner project! Below are the instructions to get everything up and running locally.

### Prerequisites
- Flutter SDK `^3.10.7`
- Dart SDK
- Android Studio / Xcode (for emulation and building)

### Installation
1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/qr_scanner.git
   cd qr_scanner
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   Connect your physical device or start an emulator, then run:
   ```bash
   flutter run
   ```

### Working with the Codebase
- **Adding new features**: Please create a new folder under `lib/features/`. Do not pollute existing feature folders unless your code directly pertains to them.
- **Reusable UI Components**: Any UI widget that is used across multiple features should be placed in `lib/common/`.
- **Translations**: If you are adding strings, ensure you update the translation files appropriately, as this app utilizes `easy_localization`.

### Native Permissions Required
If your PR introduces new features utilizing the device hardware, ensure you have requested the necessary capabilities in both platforms:
- **Android**: Update `android/app/src/main/AndroidManifest.xml`
- **iOS**: Update `ios/Runner/Info.plist`
*(Currently required permissions: Camera, Photo Library access, Contacts access, Microphone/Audio).*

---

## 👨‍💻 Developer Profile Summary

**For Portfolio / Professional Profile Use:**
> *"Engineered a comprehensive, feature-based QR and Barcode Scanner/Generator using Flutter and Dart. Designed a scalable 'feature-first' architecture that easily handles expansion. Integrated Hive NoSQL local database to persist user scan history and favorites efficiently. Leveraged Provider for robust state management. Delivered a polished user experience with deep native hardware integration, including camera streaming, gallery exports, haptic/audio feedback, and dynamic dark/light theme support. Strict adherence to clean architecture principles by distinctly separating core services, common UI elements, and distinct feature modules."*

---

## 📄 License
This project is open-source and available under the MIT License.
