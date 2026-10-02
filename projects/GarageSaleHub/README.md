# GarageSaleHub

A marketplace app for local garage sales. People can post items with photos, price, and location, browse everyone's listings in real time, and see where an item is on a map.

## Features

- **Accounts**: email/password sign-up and login with Firebase Authentication
- **Posting items**: title, description, price, condition, and contact info, with up to 4 photos from the gallery
- **Image storage**: photos upload to Firebase Storage, and download URLs are retried if they fail
- **Location**: fills in the seller's current location (Geolocator + Geocoding) and shows it on Google Maps
- **Live feed**: listings stream from Cloud Firestore and update on every device in real time
- **Item details**: image carousel with full-screen zoom, map preview, and delete for the owner only
- **Seed data**: a helper fills an empty database with sample listings for demos
- **Security rules**: `firestore.rules` limits writes to signed-in users

## Tech Stack

Flutter · Firebase Auth · Cloud Firestore · Firebase Storage · google_maps_flutter · geolocator · geocoding · image_picker

## Project Structure

```
lib/
├── models/post_model.dart
├── screens/        # welcome, login, signup, browse, new post, detail, full-screen image
└── services/sample_data_seed.dart
```

## Setup

This app uses Firebase. Config files are not committed, so connect it to your own project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure     # writes lib/firebase_options.dart and the platform config files
flutter pub get
flutter run
```

You also need a Google Maps API key with the Maps SDK for Android/iOS enabled. Replace `YOUR_GOOGLE_MAPS_API_KEY` in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/AppDelegate.swift`
