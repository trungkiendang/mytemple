import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

/// Shown while the app initialises (local storage, Firebase). Matches the native / web
/// splash (dark wood + emblem) so there is no white flash on start-up.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.7, curve: Curves.easeOut));
    final scale = Tween<double>(begin: 0.88, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    return Scaffold(
      backgroundColor: const Color(0xFF2A1710),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.2), radius: 1.1, colors: [Color(0xFF5C3022), Color(0xFF1E100B)]),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Image.asset('assets/icon/splash_logo.png', width: 220, height: 220),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1, curve: Curves.easeOut)),
                child: Column(
                  children: [
                    const Text('My Chùa',
                        style: TextStyle(color: AppTheme.gold, fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    Text('Tĩnh tâm · Thắp hương · Gõ mõ',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, letterSpacing: 0.6)),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppTheme.antiqueGold),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
