import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';

/// الإنجازات — أوسمة محسوبة من بيانات المستخدم الفعلية في Hive
/// + ملخّص «أسبوعك مع مُلتزم».
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static String _dayKey(DateTime d) => 'log_${d.year}-${d.month}-${d.day}';

  Map<String, String>? _log(Box box, DateTime d) {
    final raw = box.get(_dayKey(d));
    return raw is Map ? Map<String, String>.from(raw) : null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final box = ref.watch(hiveBoxProvider);
    final now = DateTime.now();

    // ── حسابات من البيانات الفعلية ──────────────────────────
    var fajrStreak = 0;
    for (var i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final has = _log(box, d)?.containsKey('fajr') ?? false;
      if (i == 0 && !has) continue; // فجر اليوم لم يحن بعده ربما
      if (has) {
        fajrStreak++;
      } else {
        break;
      }
    }

    var fullDay = false;
    for (var i = 0; i < 14 && !fullDay; i++) {
      final l = _log(box, now.subtract(Duration(days: i)));
      if (l != null && l.values.where((v) => v.isNotEmpty).length >= 5) {
        fullDay = true;
      }
    }

    var thursdayFast = false;
    for (var i = 0; i < 30 && !thursdayFast; i++) {
      final d = now.subtract(Duration(days: i));
      if (d.weekday == DateTime.thursday &&
          box.get('fast_${d.year}-${d.month}-${d.day}') != null) {
        thursdayFast = true;
      }
    }

    final tasbih = box.get('tasbih_total', defaultValue: 0) as int;
    final donations =
        (box.get('donations', defaultValue: const []) as List).length;
    final khatDays = box.get('khat_days') as int?;
    final khatDone = box.get('khat_done', defaultValue: 0) as int;
    final readStarted = box.get('quran_last') != null;

    final badges = <(String, IconData, String, bool)>[
      ('المواظب', Icons.mosque_rounded, 'أتممت صلواتك الخمس في يوم واحد', fullDay),
      ('حارس الفجر', Icons.wb_twilight, 'سلسلة فجر ٣ أيام متتالية', fajrStreak >= 3),
      ('صائم الخميس', Icons.eco_rounded, 'صمت يوم خميس وسجّلته', thursdayFast),
      ('قارئ الورد', Icons.menu_book_rounded, 'حفظت علامة قراءة في المصحف', readStarted),
      ('ماشي الختمة', Icons.auto_stories_rounded, 'لديك خطة ختمة وأنجزت منها', khatDays != null && khatDone > 0),
      ('نصف الطريق', Icons.workspace_premium_rounded, 'أنجزت ٥٠٪ من خطة الختمة', khatDays != null && khatDays > 0 && khatDone / khatDays >= 0.5),
      ('سيد الذكر', Icons.fingerprint, '١٠٠٠ تسبيحة إجمالية', tasbih >= 1000),
      ('الكريم الهمام', Icons.volunteer_activism_rounded, '٧ صدقات مسجّلة', donations >= 7),
    ];
    final unlocked = badges.where((b) => b.$4).length;

    return Scaffold(
      appBar: AppBar(title: const Text('إنجازاتي')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ── ملخّص أسبوعي ───────────────────────────────────
        OrnamentedCard(
          color: AppColors.emerald,
          child: Column(children: [
            Text('أسبوعك مع مُلتزم 🤍',
                style: AppTheme.amiri(19, color: Colors.white)),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _mini('فجر متتالٍ', fajrStreak),
              _mini('تسبيحات', tasbih),
              _mini('صدقات', donations),
              _mini('أيام الختمة', khatDone),
            ]),
          ]),
        ),
        const SizedBox(height: 14),

        SectionTitle('الأوسمة (${toArabicDigits(unlocked)}/${toArabicDigits(badges.length)})'),
        const SizedBox(height: 10),

        // ── شبكة الأوسمة ───────────────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemCount: badges.length,
          itemBuilder: (context, i) {
            final (name, icon, desc, on) = badges[i];
            return Card(
              color: on ? null : Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      on ? icon : Icons.lock_outline_rounded,
                      size: 34,
                      color: on ? AppColors.gold : AppColors.inkSoft,
                    ),
                    const SizedBox(height: 8),
                    Text(name,
                        style: AppTheme.amiri(17,
                            color: on ? AppColors.emerald : AppColors.inkSoft)),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, color: AppColors.inkSoft, height: 1.5),
                    ),
                    if (on)
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text('✦ مُفتَح',
                            style: TextStyle(fontSize: 10, color: AppColors.success)),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          '«أحب الأعمال إلى الله أدومها وإن قلَّ» — المشاركة والعرض للمتابعة الذاتية لا للفخر 🤍',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppColors.inkSoft),
        ),
      ]),
    );
  }

  Widget _mini(String label, int value) => Column(children: [
        Text(toArabicDigits(value),
            style: AppTheme.amiri(22, color: AppColors.goldLight)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]);
}
