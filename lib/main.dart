import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/tts_service.dart';
import 'features/monk_bell/monk_bell_provider.dart';
import 'features/monk_bell/monk_bell_screen.dart';
import 'features/scriptures/scripture_list_screen.dart';
import 'features/incense/incense_provider.dart';
import 'core/app_icons.dart';
import 'services/analytics_service.dart';
import 'services/firebase_status.dart';
import 'features/splash/splash_screen.dart';
import 'features/incense/incense_screen.dart';
import 'features/incense/prayer_provider.dart';
import 'features/calendar/event_provider.dart';
import 'features/calendar/lunar_calendar_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/auth_provider.dart';

// Don't block startup when Firebase is unreachable; providers fall back to mock data.
const _firebaseTimeout = Duration(seconds: 5);

// Web build-time configuration (see docs/ANALYTICS.md and docs/FIREBASE.md):
//   --dart-define=FIREBASE_WEB_APP_ID=1:609068144093:web:xxxx --dart-define=GA_MEASUREMENT_ID=G-XXXX
const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID', defaultValue: '1:609068144093:web:dummy');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Paint the splash immediately; initialisation happens behind it.
  runApp(const BootstrapApp());
}

Future<void> _initialize() async {
  await initializeDateFormatting('vi_VN', null);
  await HiveService.init();
  await NotificationService().init();

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: "AIzaSyB3QlRiiVFwixubt2cAzlUsmIV9q1qVzW0",
          appId: _webAppId,
          messagingSenderId: "609068144093",
          projectId: "temple-a6cf8",
          storageBucket: "temple-a6cf8.appspot.com",
          measurementId: AnalyticsService.webMeasurementId.isEmpty ? null : AnalyticsService.webMeasurementId,
        ),
      ).timeout(_firebaseTimeout);
    } else {
      await Firebase.initializeApp().timeout(_firebaseTimeout);
    }

    // Anonymous sign-in so Firestore rules that require auth are satisfied
    await FirebaseAuth.instance.signInAnonymously().timeout(_firebaseTimeout);
    debugPrint('Firebase & Auth initialized successfully');
  } catch (e) {
    debugPrint('Firebase init/auth error: $e');
    FirebaseStatus.report(e);
  }
  await AnalyticsService.init();
  AnalyticsService.setUser(Firebase.apps.isEmpty ? null : FirebaseAuth.instance.currentUser?.uid);
}

/// Shows the splash while [_initialize] runs (at least [_minSplash] so it does not flash).
class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  static const _minSplash = Duration(milliseconds: 1500);
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.wait([
      _initialize().catchError((Object e) => debugPrint('Init error: $e')),
      Future<void>.delayed(_minSplash),
    ]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _ready
          ? const MyApp(key: ValueKey('app'))
          : MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.theme,
              home: const SplashScreen(),
            ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MonkBellProvider()),
        ChangeNotifierProvider(create: (_) => IncenseProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
        ChangeNotifierProvider(create: (_) => TtsService()),
        ChangeNotifierProvider(create: (ctx) => PrayerProvider(ctx.read<TtsService>())),
        ChangeNotifierProvider(create: (_) => AppAuthProvider()),
      ],
      child: MaterialApp(
        title: 'My Chùa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // opens on the incense tab

  final List<Widget> _screens = [
    const MonkBellScreen(),
    const ScriptureListScreen(),
    const IncenseScreen(),
    const LunarCalendarScreen(),
    const ProfileScreen(),
  ];

  static const _screenNames = ['go_mo', 'kinh', 'thap_huong', 'lich', 'ca_nhan'];

  @override
  void initState() {
    super.initState();
    AnalyticsService.screen(_screenNames[_selectedIndex]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    AnalyticsService.screen(_screenNames[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(icon: AppIcon.moBell(), label: 'Gõ mõ'),
          NavigationDestination(icon: AppIcon.scripture(), label: 'Kinh'),
          NavigationDestination(icon: AppIcon.incense(), label: 'Thắp hương'),
          NavigationDestination(icon: AppIcon.lunar(), label: 'Lịch'),
          NavigationDestination(icon: AppIcon.lotus(), label: 'Tôi'),
        ],
      ),
    );
  }
}
