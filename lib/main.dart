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
import 'services/firebase_status.dart';
import 'features/incense/incense_screen.dart';
import 'features/incense/prayer_provider.dart';
import 'features/calendar/event_provider.dart';
import 'features/calendar/lunar_calendar_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/auth_provider.dart';

// Don't block startup when Firebase is unreachable; providers fall back to mock data.
const _firebaseTimeout = Duration(seconds: 6);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('vi_VN', null);
  await HiveService.init();
  await NotificationService().init();

  try {
    if (kIsWeb) {
      // Cấu hình dựa trên thông tin thật từ GoogleService-Info.plist của bạn
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyB3QlRiiVFwixubt2cAzlUsmIV9q1qVzW0",
          appId: "1:609068144093:web:dummy", // Web ID sẽ cần cập nhật từ Console nếu chạy Web thật
          messagingSenderId: "609068144093",
          projectId: "temple-a6cf8",
          storageBucket: "temple-a6cf8.appspot.com",
        ),
      ).timeout(_firebaseTimeout);
    } else {
      await Firebase.initializeApp().timeout(_firebaseTimeout);
    }
    
    // Tự động đăng nhập ẩn danh để vượt qua Rules của Firestore
    await FirebaseAuth.instance.signInAnonymously().timeout(_firebaseTimeout);
    debugPrint('Firebase & Auth initialized successfully');
  } catch (e) {
    debugPrint('Firebase init/auth error: $e');
    FirebaseStatus.report(e);
  }

  runApp(const MyApp());
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MonkBellScreen(),
    const ScriptureListScreen(),
    const IncenseScreen(),
    const LunarCalendarScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
