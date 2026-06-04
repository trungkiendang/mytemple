import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../monk_bell/monk_bell_provider.dart';
import '../incense/incense_provider.dart';
import 'auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getBadge(int tapCount) {
    if (tapCount < 100) {
      return 'Người mới tu tập';
    } else if (tapCount < 500) {
      return 'Phật tử tinh tấn';
    } else if (tapCount < 1000) {
      return 'Cư sĩ thuần thành';
    } else {
      return 'Cư sĩ tinh tấn';
    }
  }

  @override
  Widget build(BuildContext context) {
    final monkBellProvider = context.watch<MonkBellProvider>();
    final incenseProvider = context.watch<IncenseProvider>();
    final authProvider = context.watch<AppAuthProvider>();

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
              Text(
                authProvider.isLoggedIn
                    ? (authProvider.user?.displayName ?? 'Người dùng Temple Vibe')
                    : 'Người dùng Temple Vibe',
                style: const TextStyle(
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
                      'Tổng lượt gõ mõ',
                      monkBellProvider.tapCount.toString(),
                      Icons.notifications,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Thời gian thắp hương',
                      incenseProvider.totalIncenseFormatted,
                      Icons.fireplace,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatCard(
                'Ngày tham gia',
                '20/05/2024',
                Icons.calendar_today,
                isFullWidth: true,
              ),
              const SizedBox(height: 40),

              // Settings
              ListTile(
                leading: const Icon(Icons.settings, color: AppTheme.darkWood),
                title: const Text('Cài đặt'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              const Divider(),

              // About Author
              ListTile(
                leading: const Icon(Icons.info_outline, color: AppTheme.darkWood),
                title: const Text('Về tác giả'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAuthorDialog(context),
              ),
              const Divider(),

              // Login / Logout
              if (authProvider.isLoggedIn)
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    await authProvider.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã đăng xuất')),
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.login, color: AppTheme.woodBrown),
                  title: const Text('Đăng nhập'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLoginDialog(context),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    final emailCtl = TextEditingController();
    final passCtl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng nhập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passCtl,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ'),
          ),
          TextButton(
            onPressed: () async {
              final auth = ctx.read<AppAuthProvider>();
              final err = await auth.signIn(emailCtl.text, passCtl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                }
              }
            },
            child: const Text('Đăng nhập'),
          ),
          TextButton(
            onPressed: () async {
              final auth = ctx.read<AppAuthProvider>();
              final err = await auth.signUp(emailCtl.text, passCtl.text);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                if (err != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(err)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đăng ký thành công!')),
                  );
                }
              }
            },
            child: const Text('Đăng ký'),
          ),
        ],
      ),
    );
  }

  void _showAuthorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Về tác giả'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.lightWood,
                child: Icon(Icons.person, size: 50, color: AppTheme.darkWood),
              ),
              SizedBox(height: 12),
              Text(
                'Trung Kiên Đặng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkWood),
              ),
              SizedBox(height: 4),
              Text('Web Developer', style: TextStyle(color: AppTheme.woodBrown, fontWeight: FontWeight.w500)),
              SizedBox(height: 16),
              Text('Nhà phát triển ứng dụng Temple Vibe - Ứng dụng tâm linh giúp kết nối với Phật pháp thông qua công nghệ.',
                  style: TextStyle(fontSize: 14, height: 1.5)),
              SizedBox(height: 16),
              _InfoRow(label: 'Email', value: 'kiendangtrung@live.com'),
              SizedBox(height: 4),
              _InfoRow(label: 'Telegram', value: '@trungkiendang'),
              SizedBox(height: 4),
              _InfoRow(label: 'Website', value: 'iamkien.tech'),
              SizedBox(height: 16),
              Text('Kinh nghiệm:', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkWood)),
              SizedBox(height: 4),
              Text('• Giám đốc Trung tâm Quản lý Phần mềm - Viettel\n'
                  '• Kiến trúc sư giải pháp - TPBank\n'
                  '• Senior Developer - BTSoftVN\n'
                  '• Full-stack Developer - VIEGRID',
                  style: TextStyle(fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {bool isFullWidth = false}) {
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
        crossAxisAlignment: isFullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
