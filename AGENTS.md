# AGENTS.md

## Commands
- `flutter pub get` — install deps
- `dart run build_runner build --delete-conflicting-outputs` — regenerate Hive `.g.dart` adapters (typeId 0=Scripture, 1=CalendarEvent)
- `flutter analyze` — lint/static analysis (uses `flutter_lints`, no custom rules)
- `flutter test` — run tests (single smoke test at `test/widget_test.dart`)
- `flutter run` — run on connected device/emulator
- `flutter run -d chrome` — run on web (Firebase web config is hardcoded in `lib/main.dart:30-38`)
- `cd scripts && npm install && node upload_to_firebase.js` — seed Firestore with scripture data from `docs/firebase_seed.json` (requires `scripts/serviceAccountKey.json`, gitignored)

## Architecture

### Entrypoint
`lib/main.dart` — initializes: `HiveService.init()` → `NotificationService().init()` → `Firebase.initializeApp()` → `FirebaseAuth.instance.signInAnonymously()` → `runApp(MyApp)` with Provider-wrapped MaterialApp.

### Navigation
Five-tab `BottomNavigationBar` with `IndexedStack` — monk_bell, scriptures, incense, calendar, profile. Screens use `AutomaticKeepAliveClientMixin` to survive tab switches.

### State Management
Provider. Three providers registered in `MultiProvider`: `MonkBellProvider`, `IncenseProvider`, `EventProvider`. `TtsService` is also a `ChangeNotifier` provided at root.

### Firebase
- Auth: anonymous sign-in on startup (required for Firestore security rules)
- Firestore collections: `scriptures/`, `stats/global_stats` (global_taps, online_users), `users/{uid}/user_events`
- Some providers (`MonkBellProvider`, `FirebaseService`) gracefully degrade to mock data when Firebase is unavailable (check `Firebase.apps.isNotEmpty`)

### Local Storage
Hive boxes: `scriptures` (typeId 0), `events` (typeId 1), `settings` (untyped). Services layer in `lib/services/hive_service.dart`.

### Services
- `HiveService` — static methods, all-in-one wrapper
- `NotificationService` — singleton mock (only `debugPrint`); not wired to `flutter_local_notifications` yet
- `TtsService` — ChangeNotifier, uses `flutter_tts` with Vietnamese voice (`vi-VN`)
- `FirebaseService` — instance, fetches scriptures with optional `sect` filter

### Assets
- 3D models: `assets/models/mo.glb`, `assets/models/incense_bowl.glb`
- Audio: `assets/audio/bell_sound.mp3`

### Scripts Firestore Seeder
Node.js script at `scripts/upload_to_firebase.js`. Uses `firebase-admin`. Data source: `docs/firebase_seed.json`. Collections seeded: `scriptures`, `stats/global_stats`.

## Key Conventions
- All UI strings in Vietnamese
- Theme colors in `lib/core/app_theme.dart` (darkWood, woodBrown, parchment, etc.)
- Feature directories (`lib/features/{monk_bell,incense,scriptures,calendar,profile,community}/`) each contain their own screen + provider
- Models in `lib/models/` use Hive annotations with `@HiveType` and `@HiveField`; generated adapters committed
- Package name for native configs: `com.kun.temple`
- No git hooks, no CI/CD workflows
