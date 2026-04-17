import 'package:flutter/material.dart';
import '../../models/scripture.dart';
import '../../services/firebase_service.dart';
import '../../services/hive_service.dart';
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
        title: const Text('Scripture Library'),
      ),
      body: FutureBuilder<List<Scripture>>(
        future: _scripturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No scriptures found.'));
          }

          final scriptures = snapshot.data!;
          return ListView.builder(
            itemCount: scriptures.length,
            itemBuilder: (context, index) {
              final scripture = scriptures[index];
              final isDownloaded = HiveService.getScripture(scripture.id) != null;

              return ListTile(
                title: Text(scripture.title),
                trailing: isDownloaded
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.download),
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
                        builder: (context) => ScriptureDetailScreen(scripture: scripture),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
