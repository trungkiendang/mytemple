import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/app_theme.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'features/monk_bell/monk_bell_provider.dart';
import 'features/monk_bell/monk_bell_screen.dart';
import 'features/scriptures/scripture_list_screen.dart';
import 'features/incense/incense_provider.dart';
import 'features/incense/incense_screen.dart';
import 'features/calendar/lunar_calendar_screen.dart';
import 'features/profile/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Localization
  await initializeDateFormatting('vi_VN', null);

  // Initialize Hive
  await HiveService.init();
  
  // Initialize Notifications
  await NotificationService().init();

  // Firebase initialization placeholder
  // Note: Requires platform-specific configuration files to work properly
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization skipped or failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MonkBellProvider()),
        ChangeNotifierProvider(create: (_) => IncenseProvider()),
      ],
      child: const TempleVibeApp(),
    ),
  );
}

class TempleVibeApp extends StatelessWidget {
  const TempleVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temple Vibe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainScreen(),
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

  static const List<Widget> _screens = [
    MonkBellScreen(),
    ScriptureListScreen(),
    IncenseScreen(),
    LunarCalendarScreen(),
    ProfileScreen(),
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
        selectedItemColor: AppTheme.woodBrown,
        unselectedItemColor: AppTheme.darkWood.withOpacity(0.5),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Mõ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books_outlined),
            activeIcon: Icon(Icons.library_books),
            label: 'Kinh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fireplace_outlined),
            activeIcon: Icon(Icons.fireplace),
            label: 'Hương',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Lịch',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.temple_hindu,
              size: 100,
              color: AppTheme.woodBrown,
            ),
            SizedBox(height: 20),
            Text(
              'Temple Vibe',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkWood,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
