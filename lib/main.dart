import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'services/hive_service.dart';
import 'features/monk_bell/monk_bell_provider.dart';
import 'features/monk_bell/monk_bell_screen.dart';
import 'features/scriptures/scripture_list_screen.dart';
import 'features/incense/incense_provider.dart';
import 'features/incense/incense_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await HiveService.init();
  
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
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Mõ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Kinh',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fireplace),
            label: 'Hương',
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
