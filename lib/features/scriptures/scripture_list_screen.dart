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
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Scripture>> _scripturesFuture;
  String? _selectedSect;
  String _searchQuery = '';

  final List<String> _sects = ['Bắc tông', 'Nam tông', 'Khất sĩ', 'Mật tông'];

  @override
  void initState() {
    super.initState();
    _fetchScriptures();
  }

  void _fetchScriptures() {
    _scripturesFuture =
        _firebaseService.fetchScripturesFromFirebase(sect: _selectedSect);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thư Viện Kinh Sách'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm kinh sách...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.woodBrown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedSect == null,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedSect = null;
                        _fetchScriptures();
                      });
                    }
                  },
                  selectedColor: AppTheme.woodBrown.withOpacity(0.2),
                  checkmarkColor: AppTheme.woodBrown,
                ),
                const SizedBox(width: 8),
                ..._sects.map((sect) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(sect),
                      selected: _selectedSect == sect,
                      onSelected: (selected) {
                        setState(() {
                          _selectedSect = selected ? sect : null;
                          _fetchScriptures();
                        });
                      },
                      selectedColor: AppTheme.woodBrown.withOpacity(0.2),
                      checkmarkColor: AppTheme.woodBrown,
                    ),
                  );
                }),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Scripture>>(
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
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: () => setState(() {
                            _fetchScriptures();
                          }),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('Không tìm thấy kinh sách nào.'));
                }

                final allScriptures = snapshot.data!;
                final filteredScriptures = allScriptures.where((s) {
                  return s.title.toLowerCase().contains(_searchQuery) ||
                      s.content.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredScriptures.isEmpty) {
                  return const Center(child: Text('Không tìm thấy kết quả.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredScriptures.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final scripture = filteredScriptures[index];
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.lightWood,
                          child: Icon(Icons.book, color: AppTheme.darkWood),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                scripture.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkWood,
                                ),
                              ),
                            ),
                            if (scripture.sect != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.woodBrown.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  scripture.sect!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.woodBrown,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          isDownloaded ? 'Đã tải xuống' : 'Nhấn để tải và đọc',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDownloaded ? Colors.green : Colors.grey,
                          ),
                        ),
                        trailing: isDownloaded
                            ? const Icon(Icons.chevron_right,
                                color: AppTheme.woodBrown)
                            : const Icon(Icons.download,
                                color: AppTheme.woodBrown),
                        onTap: () async {
                          final navigator = Navigator.of(context);
                          if (!isDownloaded) {
                            await HiveService.saveScripture(scripture);
                            if (mounted) {
                              setState(() {});
                            }
                          }
                          navigator.push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ScriptureDetailScreen(scripture: scripture),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
