import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/tajweed_data.dart';
import 'quiz_tab.dart';
import 'repeat_mode_tab.dart';

/// علّمني القرآن — منهج تجويد ميسّر + تلقين صوتي + اختبار + تتبّع تقدّم.
class LearnQuranScreen extends ConsumerWidget {
  const LearnQuranScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(hiveBoxProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('علِّمني القرآن'),
          bottom: const TabBar(tabs: [
            Tab(text: 'المنهج'),
            Tab(text: 'التلقين'),
            Tab(text: 'اختبر نفسك'),
          ]),
        ),
        body: TabBarView(children: [
          // ── تبويب ١: المنهج (يتجدد تلقائياً عند إتقان أي درس) ──
          ValueListenableBuilder(
            valueListenable: box.listenable(keys: const ['learn_done']),
            builder: (context, _, __) {
              final done =
                  (box.get('learn_done', defaultValue: const []) as List).toSet();
              return _CurriculumTab(
                done: done,
                progress: done.length / kTajweedCurriculum.length,
              );
            },
          ),
          // ── تبويب ٢: التلقين الصوتي ────────────────────────
          const RepeatModeTab(),
          // ── تبويب ٣: الاختبار ──────────────────────────────
          const QuizTab(),
        ]),
      ),
    );
  }
}

class _CurriculumTab extends ConsumerWidget {
  const _CurriculumTab({required this.done, required this.progress});

  final Set<dynamic> done;
  final double progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(hiveBoxProvider);

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── تقدّم المتعلّم ─────────────────────────────────────
      OrnamentedCard(
        color: AppColors.emerald,
        child: Column(children: [
          Text('مسيرتك في التجويد 🤍',
              style: AppTheme.amiri(18, color: Colors.white)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: AppColors.goldLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'أتقنت ${toArabicDigits(done.length)} من ${toArabicDigits(kTajweedCurriculum.length)} درساً',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ]),
      ),
      const SizedBox(height: 14),

      // ── الدروس المستوية ────────────────────────────────────
      for (var level = 1; level <= 3; level++) ...[
        SectionTitle(kLevelNames[level]!),
        const SizedBox(height: 8),
        for (final l in kTajweedCurriculum.where((l) => l.level == level))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _LessonTile(
              lesson: l,
              done: done.contains(l.id),
              onToggle: () {
                final set = done..remove('') ;
                set.contains(l.id) ? set.remove(l.id) : set.add(l.id);
                box.put('learn_done', set.toList());
              },
            ),
          ),
      ],

      // ── مخارج الحروف ───────────────────────────────────────
      const SectionTitle('مخارج الحروف التفصيلية'),
      const SizedBox(height: 8),
      OrnamentedCard(
        child: Column(children: [
          for (final (place, letters, note) in kMakhrajGroups)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.emerald.withValues(alpha: 0.1),
                  child: const Icon(Icons.hearing, size: 14, color: AppColors.emerald),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(place,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(letters,
                        style: GoogleFonts.amiri(
                            fontSize: 16, color: AppColors.emerald)),
                    if (note.isNotEmpty)
                      Text(note,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.inkSoft)),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 16),
    ]);
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.done,
    required this.onToggle,
  });

  final TajLesson lesson;
  final bool done;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(
            done ? Icons.check_circle : Icons.menu_book_outlined,
            color: done ? AppColors.success : AppColors.gold,
          ),
          title: Text(lesson.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
          subtitle: Text(kLevelNames[lesson.level]!.split('—').last.trim(),
              style: const TextStyle(fontSize: 10, color: AppColors.inkSoft)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            Text(lesson.rule, style: const TextStyle(fontSize: 13.5, height: 1.9)),
            if (lesson.letters != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('📝 ${lesson.letters}',
                    style: const TextStyle(fontSize: 12.5, height: 1.7)),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                'مثال: ${lesson.example}',
                style: GoogleFonts.amiri(fontSize: 17, height: 1.7),
              ),
            ),
            if (lesson.tip != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('💡 ${lesson.tip}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.warning, height: 1.7)),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: done
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.replay, size: 16),
                      label: const Text('مُتقَن — أعد الدراسة؟'),
                      onPressed: onToggle,
                    )
                  : FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('أتقنت هذا الدرس'),
                      onPressed: onToggle,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
