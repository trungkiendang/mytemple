import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../monk_bell/monk_bell_provider.dart';
import '../incense/incense_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getBadge(int tapCount) {
    if (tapCount < 100) {
      return "Người mới tu tập";
    } else if (tapCount < 500) {
      return "Phật tử tinh tấn";
    } else if (tapCount < 1000) {
      return "Cư sĩ thuần thành";
    } else {
      return "Cư sĩ tinh tấn";
    }
  }

  @override
  Widget build(BuildContext context) {
    final monkBellProvider = context.watch<MonkBellProvider>();
    // For now, we don't have total incense time in provider, so we'll mock it or add it later
    // final incenseProvider = context.watch<IncenseProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cá nhân'),
        centerTitle: true,
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 20),
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
            const SizedBox(height: 20),
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppTheme.lightWood,
              child: Icon(
                Icons.person,
                size: 80,
                color: AppTheme.darkWood,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Người dùng Temple Vibe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkWood,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.woodBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getBadge(monkBellProvider.tapCount),
                style: const TextStyle(
                  color: AppTheme.woodBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tổng lượt gõ mõ',
                    monkBellProvider.tapCount.toString(),
                    Icons.notifications,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Thời gian thắp hương',
                    '15 phút', // Mocked for now
                    Icons.fireplace,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatCard(
              context,
              'Ngày tham gia',
              '20/05/2024', // Mocked for now
              Icons.calendar_today,
              isFullWidth: true,
            ),
            const SizedBox(height: 40),
            ListTile(
              leading: const Icon(Icons.settings, color: AppTheme.darkWood),
              title: const Text('Cài đặt'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppTheme.darkWood),
              title: const Text('Về chúng tôi'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.woodBrown, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkWood,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkWood.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
