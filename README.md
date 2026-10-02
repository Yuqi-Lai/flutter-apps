# Flutter Apps Portfolio

Eleven cross-platform Flutter apps. They range from a full marketplace app to focused demos of real-time multiplayer, on-device machine learning, maps and location, and Firebase backends.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Google Maps](https://img.shields.io/badge/Google%20Maps-4285F4?logo=googlemaps&logoColor=white)

## Featured

### [GarageSaleHub](./projects/GarageSaleHub)
A marketplace app for local garage sales. Users post items with up to 4 photos, price, and location, and browse a live feed of listings that syncs across devices.
**Stack:** Firebase Auth · Cloud Firestore · Firebase Storage · Google Maps · Geolocator · Firestore security rules

### [TicTacToe Multiplayer](./projects/TicTacToeMultiplayer)
Online two-player Tic-Tac-Toe with Google Sign-In, a game lobby, turn-based moves synced in real time, and a leaderboard.
**Stack:** Firebase Auth · Google Sign-In · Cloud Firestore (real-time listeners)

### [FaceDetectorPro](./projects/FaceDetectorPro)
A camera app that runs on-device face detection with ML Kit, uploads photos to the cloud, and keeps a photo history for each user.
**Stack:** camera · Google ML Kit · Firebase Auth / Storage / Firestore / Cloud Messaging

## All Projects

| Project | What it does | Key tech |
|---|---|---|
| [GarageSaleHub](./projects/GarageSaleHub) | Marketplace with photos, location, and a live feed | Firebase Auth, Firestore, Storage, Google Maps |
| [TicTacToeMultiplayer](./projects/TicTacToeMultiplayer) | Real-time online multiplayer game with a leaderboard | Firestore streams, Google Sign-In |
| [QuizMaster](./projects/QuizMaster) | Quiz app with a Firestore question bank, scoring, and an admin panel | Firebase Auth, Firestore, Provider |
| [TaskMaster](./projects/TaskMaster) | To-do app with locations on tasks, a map view, distance, photos, and dark mode | Firestore pagination, Google Maps, Geocoding, Provider |
| [FaceDetectorPro](./projects/FaceDetectorPro) | Face detection, cloud upload, and photo history | ML Kit, Firebase Auth / Storage / Firestore / FCM |
| [FaceDetectorLite](./projects/FaceDetectorLite) | Lighter face detection app with cloud upload | ML Kit, Firebase Storage, FCM |
| [GoogleMapsExplorer](./projects/GoogleMapsExplorer) | Google offices worldwide on an interactive map | Google Maps, HTTP, json_serializable |
| [ModernCalculator](./projects/ModernCalculator) | Calculator with button and form input modes | State management, form validation |
| [CameraIntegrationDemo](./projects/CameraIntegrationDemo) | Take a photo with the camera and show it | image_picker |
| [FlutterLayoutShowcase](./projects/FlutterLayoutShowcase) | Destination detail page built from layout widgets | Row / Column / Expanded, stateful widgets |
| [WordPairGenerator](./projects/WordPairGenerator) | Random name generator with favorites | Provider, NavigationRail |

## Skills Demonstrated

- **Firebase backend**: Authentication (email/password, Google), Cloud Firestore data modeling, real-time streams, pagination, security rules, Storage uploads, Cloud Messaging
- **Device features**: camera, gallery, GPS location, geocoding, runtime permissions
- **On-device ML**: face detection with Google ML Kit
- **Maps**: Google Maps markers, info windows, and distance calculation
- **Architecture**: separate models, screens, and services; state management with Provider; JSON serialization with code generation
- **UI**: Material 3, light/dark themes, responsive layouts, form validation

## Getting Started

Requirements: [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x.

```bash
git clone <this-repo-url>
cd <repo>/projects/<ProjectName>
flutter pub get
flutter run
```

### Firebase projects

Firebase config files and API keys are **not** committed. To run a Firebase-backed app, connect it to your own project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This writes `lib/firebase_options.dart` and the platform files (`google-services.json`, `GoogleService-Info.plist`). The platform files are in `.gitignore`.

### Google Maps projects

Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`, `ios/Runner/AppDelegate.swift`, and (for web) `web/index.html`.

## License

[MIT](LICENSE)
