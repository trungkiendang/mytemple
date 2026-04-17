import 'package:flutter/material.dart';
import '../../models/scripture.dart';
import '../../services/firebase_service.dart';
import '../../services/hive_service.dart';
import '../../core/app_theme.dart';
import 'scripture_detail_screen.dart';

class ScriptureListScreen extends StatefulWidget {
  const ScriptureListScreen({super.key});

  @override
  State<ScriptureListScreen> createState() => _ScriptureListScreenState();
}

class _ScriptureListScreenState extends State<ScriptureListScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Scripture>> _scripturesFuture;

  @override
  void initState() {
    super.initState();
    _scripturesFuture = _firebaseService.fetchScripturesFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư Viện Kinh Sách'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Scripture>>(
        future: _scripturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.woodBrown),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _scripturesFuture =
                          _firebaseService.fetchScripturesFromFirebase();
                    }),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không tìm thấy kinh sách nào.'));
          }

          final scriptures = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: scriptures.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final scripture = scriptures[index];
              final isDownloaded =
                  HiveService.getScripture(scripture.id) != null;

              return Container(
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
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: const CircleAvatar(
                    backgroundColor: AppTheme.lightWood,
                    child: Icon(Icons.book, color: AppTheme.darkWood),
                  ),
                  title: Text(
                    scripture.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkWood,
                    ),
                  ),
                  subtitle: Text(
                    isDownloaded ? 'Đã tải xuống' : 'Nhấn để tải và đọc',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDownloaded ? Colors.green : Colors.grey,
                    ),
                  ),
                  trailing: isDownloaded
                      ? const Icon(Icons.chevron_right, color: AppTheme.woodBrown)
                      : const Icon(Icons.download, color: AppTheme.woodBrown),
                  onTap: () async {
                    if (!isDownloaded) {
                      await HiveService.saveScripture(scripture);
                      if (mounted) {
                        setState(() {});
                      }
                    }
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ScriptureDetailScreen(scripture: scripture),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
