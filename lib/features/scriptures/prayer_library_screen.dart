import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/app_theme.dart';
import '../../models/scripture.dart';
import '../incense/prayer_provider.dart';
import 'scripture_detail_screen.dart';

/// "Kho văn khấn": prayers grouped into books (hằng tháng, Tết, cầu nguyện, gia đạo, lễ Phật).
class PrayerLibraryScreen extends StatelessWidget {
  const PrayerLibraryScreen({super.key});

  static const _accents = [Color(0xFF8E3B2A), Color(0xFFB23A24), Color(0xFF5D4037), Color(0xFF7A5C1E), Color(0xFF3E5C3A)];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PrayerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Kho Văn Khấn')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            '${p.prayers.length} bài khấn trong ${p.books.length} cuốn. Chạm vào bài để đọc; biểu tượng lư hương để chọn đọc khi thắp hương.',
            style: TextStyle(color: AppTheme.darkWood.withValues(alpha: 0.7), height: 1.4),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < p.books.length; i++) _BookCard(book: p.books[i], accent: _accents[i % _accents.length]),
          const SizedBox(height: 8),
          Text(
            'Nội dung văn khấn mang tính tham khảo, có thể khác nhau theo vùng miền và truyền thống từng gia đình.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppTheme.lightWood),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final PrayerBook book;
  final Color accent;
  const _BookCard({required this.book, required this.accent});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PrayerProvider>();
    final items = p.prayers.where((x) => x.book == book.id).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Row(
              children: [
                Container(
                  width: 64,
                  height: 78,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [accent, accent.withValues(alpha: 0.75)]),
                    border: const Border(right: BorderSide(color: AppTheme.antiqueGold, width: 4)),
                  ),
                  child: const Center(child: AppIcon.scripture(size: 28, color: AppTheme.gold)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.darkWood)),
                      const SizedBox(height: 3),
                      Text(book.intro, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppTheme.darkWood.withValues(alpha: 0.65))),
                      const SizedBox(height: 4),
                      Text('${items.length} bài', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.woodBrown)),
                    ],
                  ),
                ),
              ],
            ),
            children: [
              for (final x in items)
                ListTile(
                  dense: true,
                  title: Text(x.title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.darkWood)),
                  subtitle: Text(x.subtitle),
                  trailing: IconButton(
                    tooltip: 'Chọn đọc khi thắp hương',
                    icon: AppIcon.incense(size: 22, color: p.selected?.id == x.id ? AppTheme.antiqueGold : AppTheme.woodBrown),
                    onPressed: () {
                      context.read<PrayerProvider>().select(x);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(content: Text('Sẽ đọc “${x.title}” khi thắp hương')));
                    },
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ScriptureDetailScreen(
                        scripture: Scripture(id: 'khan-${x.id}', title: x.title, content: x.fullText, sect: 'Văn khấn'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
