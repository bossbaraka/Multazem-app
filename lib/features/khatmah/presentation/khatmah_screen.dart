import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/providers/prayer_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/khatmah_plan.dart';

/// خطتي للختمة — ٣٠ / ٩٠ / ١٨٠ يوم، ورد يومي محسوب تلقائياً من ٦٠٤ صفحات.
class KhatmahScreen extends ConsumerStatefulWidget {
  const KhatmahScreen({super.key});

  @override
  ConsumerState<KhatmahScreen> createState() => _KhatmahScreenState();
}

class _KhatmahScreenState extends ConsumerState<KhatmahScreen> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(khatmahRepoProvider);
    final plan = repo.current();

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطتي للختمة'),
        actions: [
          if (plan != null)
            IconButton(
              tooltip: 'خطة جديدة',
              icon: const Icon(Icons.restart_alt),
              onPressed: () async {
                await repo.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: plan == null ? _buildSetup(repo) : _buildPlan(repo, plan),
    );
  }

  // ── إنشاء خطة ────────────────────────────────────────────────────
  Widget _buildSetup(KhatmahRepository repo) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      OrnamentedCard(
        color: AppColors.gold.withValues(alpha: 0.07),
        child: Column(children: [
          Text('﴿وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا﴾',
              textAlign: TextAlign.center, style: AppTheme.amiri(20)),
          const SizedBox(height: 6),
          const Text(
            'اختر مدة الختمة وسيحسب «مُلتزم» وردك اليومي ويذكّرك به\n(الورد = الصفحات ÷ الأيام، من ٦٠٤ صفحات)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.8, color: AppColors.inkSoft),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      const SectionTitle('اختر مدة ختمتك'),
      const SizedBox(height: 10),
      for (final (days, title, hint) in const [
        (30, 'ختمة شهر — جزء يومياً', 'حوالي ٢١ صفحة يومياً · الأشهر اختياراً'),
        (90, 'ختمة ٣ أشهر', 'حوالي ٧ صفحات يومياً · إيقاع مريح'),
        (180, 'ختمة ٦ أشهر', 'حوالي ٤ صفحات يومياً · قليل دائم'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: OrnamentedCard(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.emerald.withValues(alpha: 0.12),
                child: Text(toArabicDigits(days),
                    style: const TextStyle(
                        color: AppColors.emerald, fontWeight: FontWeight.bold)),
              ),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(hint, style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_left, color: AppColors.gold),
              onTap: () async {
                await repo.create(days);
                setState(() {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('بدأت خطتك — تقبّل الله 📖')),
                  );
                }
              },
            ),
          ),
        ),
    ]);
  }

  // ── عرض الخطة ────────────────────────────────────────────────────
  Widget _buildPlan(KhatmahRepository repo, KhatmahPlan plan) {
    final (from, to) = plan.todayRange;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // تقدّم الخطة
      OrnamentedCard(
        child: Row(children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: plan.progress,
                strokeWidth: 8,
                backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                color: AppColors.emerald,
              ),
              Text('${toArabicDigits((plan.progress * 100).round())}٪',
                  style: AppTheme.amiri(18)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ختمة ${toArabicDigits(plan.days)} يوم',
                  style: AppTheme.amiri(19, color: AppColors.emerald)),
              const SizedBox(height: 4),
              Text(
                plan.finished
                    ? 'تمّت الختمة — تقبّل الله! 🎉'
                    : 'اليوم ${toArabicDigits(plan.currentDay)} من ${toArabicDigits(plan.days)}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'الختام المتوقّع: ${DateFormat('d MMMM', 'ar').format(plan.expectedFinish)}',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
              Text(
                'أنجزت: ${toArabicDigits((plan.doneDays * plan.pagesPerDay).clamp(0, KhatmahPlan.totalPages))} / ${toArabicDigits(KhatmahPlan.totalPages)} صفحة',
                style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 16),

      // ورد اليوم
      if (!plan.finished)
        OrnamentedCard(
          color: plan.todayDone ? AppColors.success.withValues(alpha: 0.1) : null,
          child: Column(children: [
            Row(children: [
              const Icon(Icons.auto_stories_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Text('ورد اليوم 📖', style: AppTheme.amiri(18, color: AppColors.emerald)),
            ]),
            const SizedBox(height: 10),
            Text(
              'من الصفحة ${toArabicDigits(from)} إلى ${toArabicDigits(to)}',
              style: AppTheme.amiri(24),
            ),
            const Text('اقرأ من المصحف ثم أكّد الإنجاز',
                style: TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      plan.todayDone ? AppColors.success : AppColors.emerald,
                ),
                icon: Icon(plan.todayDone
                    ? Icons.check_circle
                    : Icons.check_circle_outline),
                label: Text(plan.todayDone
                    ? 'أُنجز ورد اليوم — ما شاء الله ✨'
                    : 'أتممت ورد اليوم ✓'),
                onPressed: plan.todayDone
                    ? null
                    : () async {
                        await repo.markTodayDone();
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('أحسنت! ما نور الله لك قلبك بكتابه 🤍')),
                          );
                        }
                      },
              ),
            ),
          ]),
        ),

      if (plan.finished)
        OrnamentedCard(
          color: AppColors.emerald,
          child: Column(children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppColors.goldLight, size: 44),
            const SizedBox(height: 8),
            Text('أتممت الختمة — تقبّل الله 🎉',
                style: AppTheme.amiri(20, color: Colors.white)),
            const SizedBox(height: 6),
            const Text('ابدأ ختمة جديدة لترتفع درجة في المعية',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 10),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                  side: const BorderSide(color: AppColors.goldLight)),
              onPressed: () async {
                await repo.clear();
                setState(() {});
              },
              child: const Text('ختمة جديدة'),
            ),
          ]),
        ),
    ]);
  }
}
