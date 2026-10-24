import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/prayer_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/islamic.dart';
import '../data/prayer_log.dart';

class PrayerScreen extends ConsumerWidget {
  const PrayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final times = ref.watch(prayerTimesProvider);
    final next = ref.watch(nextPrayerProvider).prayer;
    final city = ref.watch(cityNameProvider);
    final log = ref.watch(todayLogProvider);

    final entries = <(Prayer, DateTime)>[
      (Prayer.fajr, times.fajr),
      (Prayer.sunrise, times.sunrise),
      (Prayer.dhuhr, times.dhuhr),
      (Prayer.asr, times.asr),
      (Prayer.maghrib, times.maghrib),
      (Prayer.isha, times.isha),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الصلاة'),
          bottom: const TabBar(tabs: [Tab(text: 'المواقيت'), Tab(text: 'سجلّ صلواتي')]),
          actions: [
            IconButton(
              icon: const Icon(Icons.explore_outlined),
              tooltip: 'اتجاه القبلة',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('اتجاه القبلة 🕋'),
                  content: Text(
                      'ستُفعَّل بوصلة القبلة الحيّة (flutter_compass) مع اهتزاز عند الاتجاه الصحيح في الإصدار القادم.'),
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(children: [
          // ── المواقيت ───────────────────────────────────────────
          ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + 1, // + بطاقة الموقع
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              if (i == 0) return _LocationCard(city: city);
              final (prayer, time) = entries[i - 1];
              final isNext = prayer == next;
              final mark = log[prayer.name] ?? '';

              return OrnamentedCard(
                color: isNext ? AppColors.emerald : null,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: prayer == Prayer.sunrise
                      ? null // الشروق وقت إعراض — لا يُسجَّل
                      : () => _showMarkSheet(context, ref, prayer, mark),
                  child: Row(children: [
                    Icon(
                      prayer == Prayer.sunrise
                          ? Icons.wb_twilight
                          : Icons.mosque_rounded,
                      color: isNext ? AppColors.goldLight : AppColors.emerald,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          prayerName(prayer),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isNext ? Colors.white : null,
                          ),
                        ),
                        if (mark.isNotEmpty)
                          Text(
                            '✓ ${kMarkLabels[mark]}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isNext ? AppColors.goldLight : AppColors.success,
                            ),
                          ),
                      ]),
                    ),
                    Text(
                      formatTime(time),
                      style: AppTheme.amiri(
                        19,
                        color: isNext ? AppColors.goldLight : AppColors.emerald,
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),

          // ── السجل الأسبوعي (حقيقي من Hive) ──────────────────────
          const _WeekLogTab(),
        ]),
      ),
    );
  }

  void _showMarkSheet(
      BuildContext context, WidgetRef ref, Prayer prayer, String current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('سجّل صلاة ${prayerName(prayer)} 🤍',
              style: AppTheme.amiri(19, color: AppColors.emerald)),
          const SizedBox(height: 8),
          for (final (value, label, icon, color) in [
            ('onTime', 'في وقتها', Icons.check_circle, AppColors.success),
            ('jamaah', 'في جماعة 🕌', Icons.groups_rounded, AppColors.gold),
            ('qada', 'قضاءً', Icons.history_rounded, AppColors.warning),
          ])
            ListTile(
              leading: Icon(icon, color: color),
              title: Text(label),
              trailing:
                  current == value ? const Icon(Icons.check, color: AppColors.success) : null,
              onTap: () {
                ref.read(todayLogProvider.notifier).set(prayer.name, value);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تقبّل الله 🕌')),
                );
              },
            ),
          if (current.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.close, color: AppColors.error),
              title: const Text('إلغاء التسجيل'),
              onTap: () {
                ref.read(todayLogProvider.notifier).remove(prayer.name);
                Navigator.pop(ctx);
              },
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  const _LocationCard({required this.city});

  final String city;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrnamentedCard(
      color: AppColors.gold.withValues(alpha: 0.08),
      child: Row(children: [
        const Icon(Icons.place_rounded, color: AppColors.emerald),
        const SizedBox(width: 8),
        Expanded(
          child: Text('المواقيت حسب: $city · أم القرى · الشافعي',
              style: const TextStyle(fontSize: 13)),
        ),
        TextButton.icon(
          icon: const Icon(Icons.my_location, size: 16),
          label: const Text('تحديث'),
          onPressed: () async {
            try {
              final r = await LocationService.detectAndApply(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('تم تحديث موقعك: ${r.city} 📍')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('تعذّر تحديد الموقع — فعّل الإذن وخدمة الموقع')),
                );
              }
            }
          },
        ),
      ]),
    );
  }
}

class _WeekLogTab extends ConsumerWidget {
  const _WeekLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekRatiosProvider);
    final hasAnyData = week.any((e) => e.$2 > 0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        SectionTitle(
          'التزامك آخر ٧ أيام',
          trailing: TextButton.icon(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('الأذان'),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (day, ratio) in week)
              Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 26,
                  height: ratio == 0 ? 12 : 118 * ratio + 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: ratio == 0
                          ? [
                              AppColors.inkSoft.withValues(alpha: 0.2),
                              AppColors.inkSoft.withValues(alpha: 0.2),
                            ]
                          : const [AppColors.emerald, AppColors.gold],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 6),
                Text(day,
                    style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
              ]),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          hasAnyData
              ? 'ما شاء الله — «أحب الأعمال إلى الله أدومها وإن قلّ» 🤍'
              : 'اضغط أي صلاة في تبويب «المواقيت» لتسجيلها (في وقتها / جماعة / قضاءً) وابدأ سلسلتك.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.inkSoft, fontSize: 12, height: 1.8),
        ),
      ]),
    );
  }
}
