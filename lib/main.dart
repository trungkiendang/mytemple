import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'features/incense/incense_screen.dart';
import 'features/calendar/event_provider.dart';
import 'features/calendar/lunar_calendar_screen.dart';
import 'features/profile/profile_screen.dart';

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
      );
    } else {
      await Firebase.initializeApp();
    }
    
    // Tự động đăng nhập ẩn danh để vượt qua Rules của Firestore
    await FirebaseAuth.instance.signInAnonymously();
    debugPrint('Firebase & Auth initialized successfully');
  } catch (e) {
    debugPrint('Firebase init/auth error: $e');
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.darkWood,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Mõ'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Kinh'),
          BottomNavigationBarItem(icon: Icon(Icons.wb_sunny), label: 'Hương'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Lịch'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tôi'),
        ],
      ),
    );
  }
}
