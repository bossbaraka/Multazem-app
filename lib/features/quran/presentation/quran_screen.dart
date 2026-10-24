import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../data/quran_repository.dart';
import '../data/surah_index.dart';
import 'surah_reader_screen.dart';

/// المرحلة ٢: المصحف الكامل بتلاوات وتفسير وحفظ.
/// الحالي: فهرس السور + بحث + آخر قراءة (هيكل جاهز للتوسعة).
class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final surahs = _query.isEmpty
        ? kSurahIndex
        : kSurahIndex
            .where((s) => s.name.contains(_query) || '${s.number}' == _query.trim())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('القرآن الكريم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_rounded),
            tooltip: 'علِّمني القرآن',
            onPressed: () => context.push('/learn-quran'),
          ),
          IconButton(
            icon: const Icon(Icons.auto_stories_rounded),
            tooltip: 'خطتي للختمة',
            onPressed: () => context.push('/khatmah'),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_added_outlined),
            tooltip: 'آخر قراءة',
            onPressed: () {
              final last = QuranRepository(Hive.box('multazim')).lastRead();
              if (last == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('لم تحفظ علامة بعد — افتح أي سورة وثبّت آخر قراءتك 📖')));
                return;
              }
              final meta = kSurahIndex[(last['surah'] as int) - 1];
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SurahReaderScreen(surah: meta)),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'ابحث باسم السورة أو رقمها…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: surahs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final s = surahs[i];
          return ListTile(
            leading: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 1.4),
                color: AppColors.emerald.withValues(alpha: 0.08),
              ),
              child: Text(
                toArabicDigits(s.number),
                style: const TextStyle(
                    color: AppColors.emerald, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('سورة ${s.name}', style: AppTheme.amiri(19)),
            subtitle: Text('${s.revelation} · آياتها ${toArabicDigits(s.ayahs)}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            trailing: const Icon(Icons.chevron_left, color: AppColors.gold),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SurahReaderScreen(surah: s)),
            ),
          );
        },
      ),
    );
  }
}
